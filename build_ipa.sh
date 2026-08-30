#!/bin/bash
set -e

echo "🚀 Avvio compilazione locale WebSyncroClient per iOS..."

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

rm -rf ./build
mkdir -p ./build/Payload

echo "📦 1/2 Compilazione archivio con xcodebuild..."
xcodebuild -project WebSyncroClient.xcodeproj \
  -scheme WebSyncroClient \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath ./build/WebSyncroClient.xcarchive \
  archive \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=""

echo "📦 2/2 Confezionamento .ipa..."
cp -r ./build/WebSyncroClient.xcarchive/Products/Applications/WebSyncroClient.app ./build/Payload/
cd ./build
zip -qr WebSyncroClient.ipa Payload
rm -rf Payload

echo "✅ Completato con successo!"
echo "📍 Il file IPA è pronto in: $DIR/build/WebSyncroClient.ipa"

