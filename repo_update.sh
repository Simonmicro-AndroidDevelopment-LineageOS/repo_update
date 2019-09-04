#!/bin/bash

# exit script immediately if a command fails
set -e

# Some people require insecure proxies
HTTP=https
if [ "$INSECURE_PROXY" = "TRUE" ]; then
    HTTP=http
fi

ANDROOT=$PWD

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

apply_gerrit_cl_commit() {
    _ref=$1
    _commit=$2
    # Check whether the commit is already stored
    if [ -z $(git rev-parse --quiet --verify $_commit^{commit}) ]
    # If not, fetch the ref from $LINK
    then
        git fetch $LINK $_ref
        _fetched=$(git rev-parse FETCH_HEAD)
        if [ $_fetched != $_commit ]
        then
            echo "$(pwd): WARNING:"
            echo -e "\tFetched commit is not $_commit"
            echo -e "\tPlease update the commit hash for $_ref to $_fetched"
        fi
        git cherry-pick FETCH_HEAD
    else
        git cherry-pick $_commit
    fi
}

apply_local_patches() {
    _path="${PWD#"$ANDROOT/"}"

    for patch in $ANDROOT/vendor/oss/repo_update/$_path/*.patch
    do
        echo applying $patch
        git am $patch
    done
}

if [ "$SKIP_SYNC" != "TRUE" ]; then
    pushd $ANDROOT/.repo/local_manifests
    git pull
    popd

    repo sync -j8 --current-branch --no-tags
fi

pushd $ANDROOT/hardware/qcom/data/ipacfg-mgr/sdm845
LINK=$HTTP && LINK+="://android.googlesource.com/platform/hardware/qcom/sdm845/data/ipacfg-mgr"
# guard use of kernel sources
# Change-Id: Ie8e892c5a7cca28cc58cbead88a9796ebc80a9f8
apply_gerrit_cl_commit refs/changes/23/834623/1 d8c88764440b0114b5f10bd9561a6b5dc4aab0e3
popd

pushd $ANDROOT/hardware/qcom/gps
LINK=$HTTP && LINK+="://android.googlesource.com/platform/hardware/qcom/gps"
# gps: use TARGET_BOARD_AUTO to override qcom hals
# Change-Id: I28898df1e8855347129039b5cb0d43975d3a5415
apply_gerrit_cl_commit refs/changes/47/728147/2 147270f08ac33d737405afc555b3ddb6f1308336
# Revert "Remove etc folder under hardware/qcom/gps"
git revert --no-edit 484979c524067125b56d59afb102003ff48e3702
# Revert "Handle updating the carrier configuration"
git revert --no-edit f475797d3c031ae97a393fa3e899034836fe7ba6
# Revert "FR 46082 - SUPL Network Setup Improvements"
git revert --no-edit 35a95e0a9bc9aeab1bb1847180babda2da5fbf90
# Revert "DO NOT MERGE: Revert "Revert "sdm845: Add libprocessgroup dependency to set_sched_policy users""
git revert --no-edit db96236976a195bda833d821d584bc76ea4cdbae

apply_local_patches

LINK=$HTTP && LINK+="://android.googlesource.com/platform/hardware/qcom/sdm845/gps"
# gps: sdm845: gnss: use correct format specifier in log
# Change-Id: I24ad0342d6d26f1c7fe2fcac451a71bbfba8bfe0
apply_gerrit_cl_commit refs/changes/39/804439/1 c1bdb439aaf7ecddd9f499dce5c7b56ea458cce4
popd

pushd $ANDROOT/hardware/qcom/audio
LINK=$HTTP && LINK+="://android.googlesource.com/platform/hardware/qcom/audio"
# hal: Correct mixer control name for 3.5mm headphone
# Change-Id: I749609aabfed53e8adb3575695c248bf9a674874
git revert --no-edit 39a2b8a03c0a8a44940ac732f636d9cc1959eff2

#Add msm8976 tasha sound card detection to msm8916 HAL
#Change-Id:  Idc5ab339bb9c898205986ba0b4c7cc91febf19de
apply_gerrit_cl_commit refs/changes/99/1112099/2 5d6e73eca6f83ce5e7375aa1bd6ed61143d30978

#hal: enable audio hal on sdm660
#Change-Id: I7bb807788e457f7ec6ce5124dfb1d88dc96d8127
apply_gerrit_cl_commit refs/changes/00/1112100/2 eeecf8a399080598e5290d3356b0ad557bd0ccbd

# hal: msm8916: Fix for vndk compilation errors
# Change-Id: Iffd8a3c00a2a1ad063e10c0ebf3ce9e88e3edea0
apply_gerrit_cl_commit refs/changes/14/777714/1 065ec9c4857fdd092d689a0526e0caeaaa6b1d72

apply_local_patches
popd

pushd $ANDROOT/hardware/qcom/media
LINK=$HTTP && LINK+="://android.googlesource.com/platform/hardware/qcom/media"
# msm8998: vdec: Add missing ifdefs for UBWC on DPB buffer decision
# Change-Id: I76131db5272b97016679c5bc0bf6ae099167cd03
apply_gerrit_cl_commit refs/changes/39/728339/1 b641243647a7cd3f382dd2be43b74f9d6b7f9310
# msm8998: mm-video-v4l2: enable compilation for both 3.18 kernel and 4.9 kernel
# Change-Id: If1eb2575dd80a1e6684c84e573baf78ae698bb20
apply_gerrit_cl_commit refs/changes/54/813054/1 01062d8acaae88b141893d69358d6c13e3495377
# msm8998: mm-video-v4l2: Renaming the AU-Delimiter params/extens
# Change-Id: I3feccfbb06e4e237a601a355ab2f2573a165ed3b
apply_gerrit_cl_commit refs/changes/55/813055/1 cb97584647999d7ea8df858f2c3f4bf04f408f34
popd

pushd $ANDROOT/hardware/qcom/media/sdm845
LINK=$HTTP && LINK+="://android.googlesource.com/platform/hardware/qcom/sdm845/media"
# Avoid missing dependency error for AOSP builds
# Change-Id: I19aa7a79f60bfd1182b5846ed54bf0fbf4fe0419
apply_gerrit_cl_commit refs/changes/80/832780/1 3a2fe3ec7974f9f1e9772d0009dc4df01937f237
# guard use of kernel sources
# Change-Id: I9b8cd5200cdfcc5d5ada39e6158383e7da221ae7
apply_gerrit_cl_commit refs/changes/84/832784/1 07a63defb34cd0a18849d4488ef11a8793e6cf3b
popd

pushd $ANDROOT/hardware/qcom/bt
LINK=$HTTP && LINK+="://android.googlesource.com/platform/hardware/qcom/bt"
# bt: use TARGET_BOARD_AUTO to override qcom hals
# Change-Id: I28898df1e8855347129039b5cb0d43975d3a5415
apply_gerrit_cl_commit refs/changes/69/728569/1 e0e30f0d46ef2ff5bcb707eaf47a596cb57b65af
popd

pushd $ANDROOT/hardware/qcom/bootctrl
LINK=$HTTP && LINK+="://android.googlesource.com/platform/hardware/qcom/bootctrl"
# bootcontrol: Add TARGET_USES_HARDWARE_QCOM_BOOTCTRL
# Change-Id: I958bcf29da2ea5914ac503e9d209c75ce44f1e51
git revert --no-edit f5db01c3b14d720f3d603cfb3b887d89c2b11b28
# Android.mk: add sdm710
# Change-Id: I82f2321d580cb2fdb15d2343e39abed5ccda50b1
git revert --no-edit a8e07aecb24898d7d2b49cb785b0c193a4b134b4
# Replace hardcoded build barrier with a generic one
# Change-Id: I34ee90a2818ad23cc6b9233bdde126a0965fae0d
apply_gerrit_cl_commit refs/changes/70/728570/2 0ae34c3a19fb0a1a0bd9775199692d550af4b8f5
popd

pushd $ANDROOT/hardware/nxp/nfc
apply_local_patches
popd

pushd $ANDROOT/frameworks/base
LINK=$HTTP && LINK+="://android.googlesource.com/platform/frameworks/base"
# Add camera key long press handling
# Change-Id: I9e68032eee221c20608f0d2c491c2b308350f7f6
apply_gerrit_cl_commit refs/changes/15/727815/1 7913f55462b61c17b0700cf57d3f1a375bb4c565
# fwb: Add check for odm version
# Change-Id: Ifab6ca5c2f97840bb4192226f191e624267edb32
apply_gerrit_cl_commit refs/changes/75/728575/1 d6f654b013b00fa55b5c50f3f599df50847811bb
# Fix bug Device that can't support adoptable storage cannot read the sdcard.
# Change-Id: I7afe5078650fe646e79fced7456f90d4af8a449a
apply_gerrit_cl_commit refs/changes/05/728605/1 b6f563436ca1b1496bf6026453e5b805c856f9e6
# SystemUI: Implement burn-in protection for status-bar/nav-bar items
# Change-Id: I828dbd4029b4d3b1f2c86b682a03642e3f9aeeb9
apply_gerrit_cl_commit refs/changes/40/824340/1 6272c6244d2b007eb6ad08fb682d77612555d1ac
popd

# because "set -e" is used above, when we get to this point, we know
# all patches were applied successfully.
echo "+++ all patches applied successfully! +++"

set +e
