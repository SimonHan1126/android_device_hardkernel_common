#!/system/bin/sh
#
# Makes MacrostockStarter the device owner, so it can push TeamViewer Host's
# managed configuration (ConfigurationID) and assign the device automatically.
#
# Why this runs as a root init service instead of from inside the app:
# DevicePolicyManagerService.checkDeviceOwnerProvisioningPreConditionLocked() has two
# paths. An app calling setDeviceOwner() with MANAGE_PROFILE_AND_DEVICE_OWNERS takes the
# non-adb branch, which returns STATUS_USER_SETUP_COMPLETED once
# Settings.Secure.user_setup_complete is 1 - and packages/apps/Provision sets that on
# first boot, long before the app could act. The adb branch is more permissive, and
# isAdb() is `isShellUid(caller) || isRootUid(caller)`, so a root caller may still set
# the device owner after setup, provided there is one user and no accounts.
#
# This replaces the manual step:
#   adb shell dpm set-device-owner \
#       com.tepari.macrostock.macrostock_starter/.receiver.AdminReceiver
#
# It runs on every boot and is a no-op once the owner is set. That is deliberate: after
# a factory reset /data is wiped and the device owner is gone, so this re-provisions
# without anyone touching adb.
#
# Launched by device/hardkernel/common/init/macrostock_device_owner.rc as uid shell in
# u:r:shell:s0 - the same identity the manual adb command runs as. That needs no new
# sepolicy and does not depend on SELinux being permissive.

TAG=MS_DEVICE_OWNER
ADMIN="com.tepari.macrostock.macrostock_starter/.receiver.AdminReceiver"

if dumpsys device_policy 2>/dev/null | grep -q "macrostock_starter/.*AdminReceiver"; then
    log -t "$TAG" "device owner already set, nothing to do"
    exit 0
fi

OUT="$(dpm set-device-owner "$ADMIN" 2>&1)"
RC=$?
if [ "$RC" -eq 0 ]; then
    log -t "$TAG" "device owner set: $OUT"
else
    # Most likely causes: an account exists, more than one user, or the starter is not
    # installed yet. dpm's own message says which.
    log -t "$TAG" "FAILED (rc=$RC) to set device owner: $OUT"
fi
exit 0
