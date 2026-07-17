#!/bin/bash
# Sets up a writable Android SDK inside the mounted repo (output/android-sdk)
# with the extra components needed to build termux-am from source.
#
# The SDK shipped in the builder docker image cannot be written to from the
# exec environment (restricted AppArmor profile denies setuid, so no sudo
# either), and building termux-am needs platforms;android-33 and
# build-tools;30.0.3 which the image SDK does not include. output/ is the
# one repo path the restricted profile allows writing to.
#
# The build step must run with ANDROID_HOME pointing at this SDK
# (properties.sh respects a pre-set ANDROID_HOME).
set -e -u

REPO_DIR="/home/builder/termux-packages"

# setup-android-sdk.sh unzips into "android-sdk-$TERMUX_SDK_REVISION" next to
# $ANDROID_HOME, so ANDROID_HOME must use exactly that directory name.
TERMUX_SDK_REVISION="$(bash -c ". '$REPO_DIR/scripts/properties.sh' >/dev/null 2>&1; echo \$TERMUX_SDK_REVISION")"
if [ -z "$TERMUX_SDK_REVISION" ]; then
	echo "ERROR: could not determine TERMUX_SDK_REVISION" >&2
	exit 1
fi
export ANDROID_HOME="$REPO_DIR/output/android-sdk-$TERMUX_SDK_REVISION"
mkdir -p "$REPO_DIR/output"

# Downloads commandline-tools into $ANDROID_HOME, accepts licenses and
# installs platform-tools, build-tools and the default platforms.
"$REPO_DIR/scripts/setup-android-sdk.sh"

SDK_MANAGER=""
for candidate in \
	"$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" \
	"$ANDROID_HOME/cmdline-tools/bin/sdkmanager" \
	"$ANDROID_HOME"/android-sdk-*/cmdline-tools/bin/sdkmanager; do
	if [ -x "$candidate" ]; then
		SDK_MANAGER="$candidate"
		break
	fi
done

if [ -z "$SDK_MANAGER" ]; then
	echo "ERROR: no usable sdkmanager found in $ANDROID_HOME" >&2
	find "$ANDROID_HOME" -maxdepth 4 -name sdkmanager >&2 || true
	exit 1
fi

echo "INFO: Using sdkmanager ... $SDK_MANAGER"
yes | "$SDK_MANAGER" --sdk_root="$ANDROID_HOME" \
	"platforms;android-33" \
	"build-tools;30.0.3"
echo "INFO: Extra SDK components installed into $ANDROID_HOME"
