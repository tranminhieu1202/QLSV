#!/bin/zsh
# Build, ký và tải bản macOS lên App Store Connect, rồi chờ Apple xử lý xong.
#
# Cách dùng (từ thư mục gốc repo, trên máy đã đăng nhập tài khoản Apple trong Xcode):
#
#     tools/release_appstore.sh            # build + upload
#     tools/release_appstore.sh --no-upload  # chỉ tạo build/appstore/QLGD EDU.pkg
#
# Trước mỗi lần chạy: tăng build number trong pubspec.yaml (1.1.3+7 → 1.1.3+8);
# App Store không nhận lại build number đã dùng.
#
# Vì sao cần bước "gỡ chữ ký bundle": các plugin dùng Swift Package Manager tạo
# *.bundle tài nguyên trong Contents/Resources, Xcode ký chúng bằng chứng chỉ
# Development lúc archive nhưng KHÔNG ký lại khi export cho App Store → Apple từ
# chối với ITMS-90284. Các bundle này không chứa mã chạy, nên gỡ chữ ký riêng để
# chữ ký Apple Distribution của app bao phủ chúng.
set -euo pipefail

TEAM_ID=86365H5S7K
ROOT=${0:A:h:h}
OUT=$ROOT/build/appstore
ARCHIVE=$OUT/QLGD.xcarchive
APP="$ARCHIVE/Products/Applications/QLGD EDU.app"
UPLOAD=1
[[ ${1:-} == --no-upload ]] && UPLOAD=0

cd $ROOT
BUILD_NUMBER=$(sed -n 's/^version: .*+\([0-9]*\)$/\1/p' pubspec.yaml)
echo "==> Phiên bản $(sed -n 's/^version: //p' pubspec.yaml)"

if (( UPLOAD )); then
  used=$(python3 tools/asc_api.py GET "/v1/builds?filter[app]=6826131512&filter[version]=$BUILD_NUMBER&filter[preReleaseVersion.platform]=MAC_OS" \
    | python3 -c 'import json,sys; print(len(json.load(sys.stdin).get("data", [])))')
  if (( used > 0 )); then
    echo "Build number $BUILD_NUMBER đã có trên App Store Connect. Tăng số sau dấu + trong pubspec.yaml." >&2
    exit 1
  fi
fi

echo "==> flutter build (tắt trình tự cập nhật qua GitHub)"
flutter build macos --release --dart-define=APP_STORE=true

echo "==> Archive"
rm -rf $OUT && mkdir -p $OUT
xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner -configuration Release \
  -archivePath $ARCHIVE archive -allowProvisioningUpdates -quiet \
  DEVELOPMENT_TEAM=$TEAM_ID "CODE_SIGN_IDENTITY=Apple Development"

echo "==> Gỡ chữ ký riêng của bundle tài nguyên SwiftPM"
for b in "$APP"/Contents/Resources/*.bundle(N); do
  if find "$b" -type f -perm +111 -exec file {} + | grep -q Mach-O; then
    echo "$b chứa mã thực thi, không gỡ chữ ký được – cần xem lại." >&2
    exit 1
  fi
  rm -rf "$b/Contents/_CodeSignature"
done
codesign -d --entitlements $OUT/entitlements.plist --xml "$APP"
codesign --force --sign "Apple Development" --entitlements $OUT/entitlements.plist \
  --options runtime --timestamp=none --preserve-metadata=identifier,flags "$APP"
codesign --verify --deep --strict "$APP"

destination=export
(( UPLOAD )) && destination=upload
cat > $OUT/ExportOptions.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key><string>app-store-connect</string>
	<key>teamID</key><string>$TEAM_ID</string>
	<key>signingStyle</key><string>automatic</string>
	<key>destination</key><string>$destination</string>
	<key>uploadSymbols</key><true/>
</dict>
</plist>
EOF

echo "==> Export ($destination)"
# Không dùng API key ở đây: key quyền App Manager không được ký trên cloud,
# nên export dùng tài khoản Apple đã đăng nhập trong Xcode.
xcodebuild -exportArchive -archivePath $ARCHIVE -exportPath $OUT \
  -exportOptionsPlist $OUT/ExportOptions.plist -allowProvisioningUpdates -quiet

if (( ! UPLOAD )); then
  echo "Xong: $OUT/QLGD EDU.pkg"
  exit 0
fi

echo "==> Chờ Apple xử lý build $BUILD_NUMBER"
python3 tools/asc_api.py wait-upload $BUILD_NUMBER
echo "Build $BUILD_NUMBER đã sẵn sàng trên App Store Connect."
