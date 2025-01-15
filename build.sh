#!/bin/bash

# 전체 버전 문자열 가져오기
FULL_VERSION=$(grep 'version:' pubspec.yaml | awk '{print $2}')

# 빌드 번호 추출 (포함된 +까지)
SIGNED_APK="./build/app/outputs/flutter-apk/petcarezone_${FULL_VERSION}.apk"

# APK 빌드
flutter build apk --release

# APK 경로
APK_PATH="./build/app/outputs/flutter-apk/app-release.apk"
ALIGNED_APK="./build/app/outputs/flutter-apk/app-align.apk"

# Zipalign 실행
~/Library/Android/sdk/build-tools/34.0.0/zipalign -f -v 4 "$APK_PATH" "$ALIGNED_APK"

# APK 서명
~/Library/Android/sdk/build-tools/34.0.0/apksigner sign -v \
    --out "$SIGNED_APK" \
    --ks ./android/app/amuz.jks \
    --ks-key-alias key \
    --ks-pass pass:amuzcorp010! \
    "$ALIGNED_APK"

# 결과 출력
echo "APK 생성 및 서명 완료: $SIGNED_APK"
