#!/usr/bin/env bash
# 클라우드 환경 setup script: Godot 4.7.2 + JDK 17 + Android SDK + 디버그 키스토어.
# claude.ai/code 환경 설정의 setup script에 이 파일 내용을 붙여넣는다.
# 네트워크 허용: github.com, dl.google.com, repo1.maven.org, services.gradle.org
# 빌드:  godot --headless --export-debug "Android 태블릿" out/android/SpaceBattleOfThreeKingdoms.apk
# 테스트: godot --headless --script tests/core_rules.gd
set -euo pipefail
GODOT_VER=4.7.2-stable
ANDROID_HOME=$HOME/android-sdk
CMDLINE=11076708

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq && apt-get install -y -qq openjdk-17-jdk-headless unzip wget >/dev/null

# Godot + 내보내기 템플릿
if ! command -v godot >/dev/null; then
  base=https://github.com/godotengine/godot-builds/releases/download/$GODOT_VER
  wget -nv $base/Godot_v${GODOT_VER}_linux.x86_64.zip -O /tmp/g.zip && unzip -q -o /tmp/g.zip -d /tmp/g
  install /tmp/g/Godot_v${GODOT_VER}_linux.x86_64 /usr/local/bin/godot
  wget -nv $base/Godot_v${GODOT_VER}_export_templates.tpz -O /tmp/t.zip && unzip -q -o /tmp/t.zip -d /tmp/t
  tdir=$HOME/.local/share/godot/export_templates/${GODOT_VER/-stable/.stable}
  mkdir -p "$tdir" && cp -r /tmp/t/templates/* "$tdir"
fi

# Android SDK
if [ ! -d "$ANDROID_HOME/platform-tools" ]; then
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  wget -nv https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE}_latest.zip -O /tmp/c.zip
  unzip -q -o /tmp/c.zip -d "$ANDROID_HOME/cmdline-tools" && mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
  yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --licenses >/dev/null
  "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" "platform-tools" "build-tools;35.0.1" "platforms;android-35" "cmdline-tools;latest" >/dev/null
fi

# 디버그 키스토어
ks=$HOME/debug.keystore
[ -f $ks ] || keytool -genkeypair -keystore $ks -alias androiddebugkey -storepass android -keypass android \
  -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US" >/dev/null

# 에디터 설정(Godot가 SDK·JDK 위치를 찾게 함) + 환경변수
mkdir -p $HOME/.config/godot
cat > $HOME/.config/godot/editor_settings-4.tres <<EOT
[gd_resource type="EditorSettings" format=3]
[resource]
export/android/android_sdk_path = "$ANDROID_HOME"
export/android/java_sdk_path = "/usr/lib/jvm/java-17-openjdk-amd64"
EOT
cat >> $HOME/.bashrc <<EOT
export ANDROID_HOME=$ANDROID_HOME
export GODOT_ANDROID_KEYSTORE_DEBUG_PATH=$ks
export GODOT_ANDROID_KEYSTORE_DEBUG_USER=androiddebugkey
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD=android
EOT
echo "cloud setup done"
