#!/bin/zsh
# Build bản macOS phát hành qua GitHub Releases: ký Developer ID, notarize với
# Apple và gắn vé (staple) để Gatekeeper không cảnh báo, kể cả khi máy không
# có mạng. Kết quả: build/devid/qlgd_edu-<phiên bản>-macos.zip – đúng tên mà
# trình cập nhật trong app tìm trên GitHub Release.
#
# Cách dùng (từ thư mục gốc repo, trên máy đã đăng nhập tài khoản Apple trong
# Xcode và có API key tại ~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8):
#
#     tools/release_devid.sh
#
# Rồi đính kèm file zip vào GitHub Release cùng phiên bản (CI chỉ build bản
# Windows). Bản này giữ trình tự cập nhật qua GitHub, khác bản App Store
# (tools/release_appstore.sh).
set -euo pipefail

TEAM_ID=86365H5S7K
KEY_ID=${ASC_KEY_ID:-VU7G87GY2Y}
ISSUER_ID=${ASC_ISSUER_ID:-5867cb6c-d94b-45b3-90d9-a398566bbfe9}
ROOT=${0:A:h:h}
OUT=$ROOT/build/devid
ARCHIVE=$OUT/QLGD.xcarchive
APP="$ARCHIVE/Products/Applications/QLGD EDU.app"
EXPORTED="$OUT/export/QLGD EDU.app"

cd $ROOT
VERSION=$(sed -n 's/^version: \([0-9.]*\)+.*$/\1/p' pubspec.yaml)
ZIP=$OUT/qlgd_edu-$VERSION-macos.zip
echo "==> Phiên bản $VERSION"

echo "==> flutter build (giữ trình tự cập nhật qua GitHub)"
flutter build macos --release

echo "==> Archive"
rm -rf $OUT && mkdir -p $OUT
xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner -configuration Release \
  -archivePath $ARCHIVE archive -allowProvisioningUpdates -quiet \
  DEVELOPMENT_TEAM=$TEAM_ID "CODE_SIGN_IDENTITY=Apple Development"

# Như bản App Store: bundle tài nguyên SwiftPM mang chữ ký Development mà
# export không ký lại; gỡ đi để chữ ký Developer ID của app bao phủ chúng.
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

cat > $OUT/ExportOptions.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key><string>developer-id</string>
	<key>teamID</key><string>$TEAM_ID</string>
	<key>signingStyle</key><string>automatic</string>
	<key>destination</key><string>export</string>
</dict>
</plist>
EOF

echo "==> Export (Developer ID)"
xcodebuild -exportArchive -archivePath $ARCHIVE -exportPath $OUT/export \
  -exportOptionsPlist $OUT/ExportOptions.plist -allowProvisioningUpdates -quiet
codesign --verify --deep --strict "$EXPORTED"

echo "==> Notarize (lần đầu của team có thể mất 10–30 phút)"
ditto -c -k --keepParent "$EXPORTED" $OUT/notarize.zip
xcrun notarytool submit $OUT/notarize.zip --wait \
  --key ~/.appstoreconnect/private_keys/AuthKey_$KEY_ID.p8 --key-id $KEY_ID --issuer $ISSUER_ID \
  | tee $OUT/notarize.log
grep -q "status: Accepted" $OUT/notarize.log || {
  echo "Apple không chấp nhận. Xem chi tiết: xcrun notarytool log <id> --key ... (id trong $OUT/notarize.log)" >&2
  exit 1
}
rm $OUT/notarize.zip

xcrun stapler staple "$EXPORTED"
spctl -a -t exec -vv "$EXPORTED"

ditto -c -k --sequesterRsrc --keepParent "$EXPORTED" $ZIP
echo "Xong: $ZIP"
echo "Đính kèm file này vào https://github.com/tranminhieu1202/QLSV/releases/tag/v$VERSION"
