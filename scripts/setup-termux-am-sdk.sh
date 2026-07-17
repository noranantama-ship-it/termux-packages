#!/bin/bash
# Installs extra Android SDK components needed when building termux-am
# (a Gradle Android project) from source, which the prebuilt docker image
# does not ship (it only has the platforms listed in setup-android-sdk.sh).
set -e -u

: "${ANDROID_HOME:="$HOME/lib/android-sdk-9123335"}"

SDK_MANAGER=""
for candidate in \
	"$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" \
	"$ANDROID_HOME/cmdline-tools/bin/sdkmanager"; do
	if [ -x "$candidate" ]; then
		SDK_MANAGER="$candidate"
		break
	fi
done

if [ -z "$SDK_MANAGER" ]; then
	echo "ERROR: no usable sdkmanager found in $ANDROID_HOME" >&2
	exit 1
fi

echo "INFO: Using sdkmanager ... $SDK_MANAGER"
yes | "$SDK_MANAGER" --sdk_root="$ANDROID_HOME" --licenses > /dev/null
yes | "$SDK_MANAGER" --sdk_root="$ANDROID_HOME" \
	"platforms;android-33" \
	"build-tools;30.0.3"
echo "INFO: Extra SDK components installed."
