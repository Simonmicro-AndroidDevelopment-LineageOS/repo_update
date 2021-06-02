#!/bin/bash

# exit script immediately if a command fails or a variable is unset
set -eu

# Some people require insecure proxies
HTTP=https
if [ "${INSECURE_PROXY:-}" = "TRUE" ]; then
    HTTP=http
fi

ANDROOT=$PWD

pushd() {
    command pushd "$@" > /dev/null
}

popd() {
    command popd > /dev/null
}

enter_aosp_dir() {
    [ -z "$1" ] && (echo "ERROR: enter_aosp_dir must be called with at least a path! (and optionally an alternative fetch path)"; exit 1)

    [ "$ANDROOT" != "$PWD" ] && echo "WARNING: enter_aosp_dir was not called from $ANDROOT. Please fix the script to call popd after every block of patches!"

    LINK="$HTTP://android.googlesource.com/platform/${2:-$1}"
    echo "Entering $1"
    pushd "$ANDROOT/$1"
}

apply_gerrit_cl_commit() {
    local _ref=$1
    local _commit=$2
    local _fetched

    # Check whether the commit is already stored
    if [ -z "$(git rev-parse --quiet --verify "$_commit^{commit}")" ]
    # If not, fetch the ref from $LINK
    then
        git fetch "$LINK" "$_ref"
        _fetched=$(git rev-parse FETCH_HEAD)
        if [ "$_fetched" != "$_commit" ]
        then
            echo "$(pwd): WARNING:"
            echo -e "\tFetched commit is not \"$_commit\""
            echo -e "\tPlease update the commit hash for $_ref to \"$_fetched\""
        fi
        _commit=$_fetched
    fi
    git cherry-pick "$_commit"
}

if [ "${SKIP_SYNC:-}" != "TRUE" ]; then
    pushd "$ANDROOT/.repo/local_manifests"
    git pull
    popd

    repo sync -j8 --current-branch --no-tags
fi

enter_aosp_dir vendor/qcom/opensource/data/ipacfg-mgr/sdm845 hardware/qcom/sdm845/data/ipacfg-mgr
# guard use of kernel sources
# Change-Id: Ie8e892c5a7cca28cc58cbead88a9796ebc80a9f8
apply_gerrit_cl_commit refs/changes/23/834623/2 0f42902cbc526d6d5badcece2add39d5badd1537
popd

enter_aosp_dir hardware/qcom/audio
# hal: Correct mixer control name for 3.5mm headphone
# Change-Id: I749609aabfed53e8adb3575695c248bf9a674874
git revert --no-edit 39a2b8a03c0a8a44940ac732f636d9cc1959eff2

# Switch msmnile to new Audio HAL
# Change-Id: I28e8c28822b29af68b52eb84f07f1eca746afa6d
git revert --no-edit d0d5c9135fed70a25a42f09f0e32b056bc7b15a8

# switch sm8150 to msmnile
# Change-id: I37b9461240551037812b35d96d0b2db5e30bae5f
git revert --no-edit 8e9b92d2c87e9d1cd96ef153853287cb79d5934c

#Add msm8976 tasha sound card detection to msm8916 HAL
#Change-Id:  Idc5ab339bb9c898205986ba0b4c7cc91febf19de
apply_gerrit_cl_commit refs/changes/99/1112099/2 5d6e73eca6f83ce5e7375aa1bd6ed61143d30978

#hal: enable audio hal on sdm660
#Change-Id: I7bb807788e457f7ec6ce5124dfb1d88dc96d8127
apply_gerrit_cl_commit refs/changes/00/1112100/2 eeecf8a399080598e5290d3356b0ad557bd0ccbd

# hal: msm8916: Fix for vndk compilation errors
# Change-Id: Iffd8a3c00a2a1ad063e10c0ebf3ce9e88e3edea0
apply_gerrit_cl_commit refs/changes/14/777714/1 065ec9c4857fdd092d689a0526e0caeaaa6b1d72

# hal: msm8916: Add missing bracket to close function definition.
# Change-Id: I8296a8fb551097fabf72115d2cec0849671b91ea
apply_gerrit_cl_commit refs/changes/51/1118151/1 b7c1366360089d6cd1b4b18c70085a802a6a0544
popd

enter_aosp_dir hardware/qcom/bootctrl
# Build bootctrl.sdm710 with Android.bp.
# Change-Id: Ib29d901b44ad0ec079c3e979bfdcd467e1a18377
#apply_gerrit_cl_commit refs/changes/01/965401/1 c665a9c43f379f754b4ee25df2818b6c20c5346e #Already in LineageOS
# Revert^2 "Build bootctrl.msm8998 with Android.bp.""
# Change-Id: I6a85b7885903df818deb32c40c751ac4358a6dbc
#apply_gerrit_cl_commit refs/changes/93/968693/1 1933d30528c58598d7423d8b307d8e0fd2c50ad5 #Already in LineageOS
# Build bootctrl.msm8996 with Android.bp.
# Android.mk itself will be removed in a separate CL.
# Change-Id: I864bd626d25723bd390b2453022d9cd47a54d2a2
#apply_gerrit_cl_commit refs/changes/96/967996/3 b229dfc102d5ea8e659514c61f6520ab3f9f777c #Already in LineageOS
# Remove Android.mk rules for building bootctrl.
# Change-Id: Ib110508065f47a742acd92e03ea42901e8002e4f
#apply_gerrit_cl_commit refs/changes/87/971787/1 7bde6868ff24001f8b6deb8cf643d86d71978b93 #Already in LineageOS
popd

enter_aosp_dir hardware/nxp/nfc
# hardware: nxp: Restore pn548 support to 1.1 HAL
# Change-Id: Ifbef5a5ec0928b0a90b2fc71d84872525d0cf1a6
#apply_gerrit_cl_commit refs/changes/77/980177/3 0285b720ea752c8dcf28c35d794990e982103ada #Already in LineageOS
# hardware: nxp: Restore pn547 support
# Change-Id: I226fa084d22850a8610f1d67ef30b96250fbd570
# (Cherry-picked from: I498367f676f8c8d7fc13e849509d0d8a05ec89a8)
#apply_gerrit_cl_commit refs/changes/69/980169/2 a58def9e0ce610f1a349d5de31f267129a0a2397 #Already in LineageOS
popd

enter_aosp_dir hardware/interfaces
# [android10-dev] thermal: Init module to NULL
# Change-Id: I250006ba6fe9d91e765dde1e4534d5d87aaab879
#apply_gerrit_cl_commit refs/changes/90/1320090/1 3861f7958bec14685cde5b8fee4e590cece76d68 #Already in LineageOS
popd

enter_aosp_dir frameworks/base
# Fix bug Device that can't support adoptable storage cannot read the sdcard.
# Change-Id: I7afe5078650fe646e79fced7456f90d4af8a449a
#apply_gerrit_cl_commit refs/changes/48/1295748/1 6ec651f12a9b67a9d2e41c2fe4d9a71c29d1cf34 #Already in LineageOS
# SystemUI: Implement burn-in protection for status-bar/nav-bar items
# Change-Id: I828dbd4029b4d3b1f2c86b682a03642e3f9aeeb9
#apply_gerrit_cl_commit refs/changes/40/824340/2 cf575e7f64a976918938e6ea3bc747011fb3b551 #Already in LineageOS with different commits
popd

enter_aosp_dir system/extras
# verity: Do not increment data when it is nullptr.
apply_gerrit_cl_commit refs/changes/52/1117052/1 c82514bd034f214b16d273b10c676dd63a9e603b
popd

enter_aosp_dir system/sepolicy
# property_contexts: Remove compatible guard
apply_gerrit_cl_commit refs/changes/00/1185400/1 668b7bf07a69e51a6c190d6b366d574b9e4af1d4
popd

enter_aosp_dir packages/apps/DeskClock
# DeskClock - Moved the android:targetSdkVersion to 25 to fix "Clock has stopped"
# message displayed when Alarm trigger.
# Change-Id: I75a96e1ed4acebd118c212b51b7d0e57482a66bb
#apply_gerrit_cl_commit refs/changes/26/987326/1 e6351b3b85b2f5d53d43e4797d3346ce22a5fa6f #Already in LineageOS
popd

enter_aosp_dir packages/apps/Messaging
# AOSP/Messaging - Update the Messaging version to 24 until notification
# related logic changes are made.
# Change-Id: Ic263e2c63d675c40a2cfa1ca0a8776c8e2b510b9
#apply_gerrit_cl_commit refs/changes/82/941082/1 8e71d1b707123e1b48b5529b1661d53762922400 #Already in LineageOS
popd

######## LINEAGEOS CHANGES ########
enter_aosp_dir build/soong
# soong: Whitelist (log) bison and flex for upstream dtc
# The upstream dtc requires bison and flex.
# Change-Id: Id4acec933dec8a2bfe00f39a64dbf39f9d347af4
# apply_gerrit_cl_commit refs/changes/89/267789/1 f06cdda6d9c1b2b146bdd306f2e6c7fe9fd748be # fatal: couldn't find remote ref refs/changes/89/267789/1
git fetch "https://github.com/LineageOS/android_build_soong" refs/changes/89/267789/1 && git cherry-pick FETCH_HEAD
popd

enter_aosp_dir vendor/lineage
# BoardConfigKernel: Opt-in for bison and flex
# For kernel >4.16 bison and flex are required, but there's a catch:
# not all of them have a very old dtc compiler and new ones do
# actually require a bison version >=3.0 or they will fail to build.
# For this reason, let people opt-in for bison and flex: if you
# set the env var TARGET_NEEDS_PREBUILT_FLEX_BISON to true, you will
# build the components with the prebuilt bison/flex, found in the
# Android tree; otherwise, the current system's (your distro's)
# bison/flex will be used instead.
# Test: Sony Open Devices kernel msm-4.14 now builds ok again.
# Change-Id: Id14b2482f4c633f529046b485c6ac16fcd28c45f
# apply_gerrit_cl_commit refs/changes/50/278350/1 2668f66d273003497be819cc13084502cfc2d124 # fatal: couldn't find remote ref refs/changes/50/278350/1
git fetch "https://github.com/LineageOS/android_vendor_lineage" refs/changes/50/278350/1 && git cherry-pick FETCH_HEAD
# apply local patch files, as there is no remote repo to fetch them from
git apply --reject $ANDROOT/vendor/oss/repo_update/patches/compiler/trinket.patch || true
popd

enter_aosp_dir frameworks/base
# Revert "Fix deletion of VkSemaphores in VulkanManager."
# * Some devices have set HWUI to use skiavk, but camera turns into a "slideshow" then.
#   Reverting this patch fixes this behaviour.
# * This reverts commit d92a9b158e8a473cd7860f2ea6cc9090fc294f78.
# Change-Id: I3eb87179bd2343e08ad7c10ca4bcd67d98c8b736
# apply_gerrit_cl_commit refs/changes/19/272919/1 9a5bfc6d69919464c32eff0238f02700d6275f8d # fatal: couldn't find remote ref refs/changes/19/272919/1
git fetch "https://github.com/LineageOS/android_frameworks_base" refs/changes/19/272919/1 && git cherry-pick FETCH_HEAD
popd

enter_aosp_dir packages/apps/Updater/res/values
# Yes, this is bad practice - BUT this is a xml patch and only needed for LOS17.1,
# as only in this release the xml overlay is broken. Also I do not plan to fork the
# whole updater package for just one xml "overlay".
git apply --reject $ANDROOT/vendor/oss/repo_update/patches/ota/strings.xml.patch || true
popd

enter_aosp_dir lineage-sdk/lineage/res/res/values/
# Yes, this is bad practice - BUT this is a xml patch and only needed for LOS17.1,
# as only in this release the xml overlay is broken. Also I do not plan to fork the
# whole updater package for just one xml "overlay".
git apply --reject $ANDROOT/vendor/oss/repo_update/patches/leds/config.xml.patch || true
popd

######## SODP CHANGES ########

# N/A

# because "set -e" is used above, when we get to this point, we know
# all patches were applied successfully.
echo "+++ all patches applied successfully! +++"

set +eu
