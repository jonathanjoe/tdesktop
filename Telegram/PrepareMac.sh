AppVersion=`./Version.sh | awk -F " " '{print $1}'`
AppVersionStr=`./Version.sh | awk -F " " '{print $2}'`

echo ""
echo "Preparing version $AppVersionStr.."
echo ""

if [ -d "./../Mac/Release/deploy/$AppVersionStr" ]; then
  echo "Deploy folder for version $AppVersionStr already exists!"
  exit 1
fi

if [ -f "./../Mac/Release/tupdate$AppVersion" ]; then
  echo "Update file for version $AppVersion already exists!"
  exit 1
fi

if [ ! -d "./../Mac/Release/Telegram.app" ]; then
  echo "Telegram.app not found!"
  exit 1
fi

if [ ! -d "./../Mac/Release/Telegram.app.dSYM" ]; then
  echo "Telegram.app.dSYM not found!"
  exit 1
fi

AppUUID=`dwarfdump -u "./../Mac/Release/Telegram.app/Contents/MacOS/Telegram" | awk -F " " '{print $2}'`
DsymUUID=`dwarfdump -u "./../Mac/Release/Telegram.app.dSYM" | awk -F " " '{print $2}'`
if [ "$AppUUID" != "$DsymUUID" ]; then
  echo "UUID of binary '$AppUUID' and dSYM '$DsymUUID' differ!"
  exit 1
fi

if [ ! -f "./../Mac/Release/Telegram.app/Contents/Resources/Icon.icns" ]; then
  echo "Icon.icns not found in Resources!"
  exit 1
fi

if [ ! -f "./../Mac/Release/Telegram.app/Contents/MacOS/Telegram" ]; then
  echo "Telegram not found in MacOS!"
  exit 1
fi

if [ ! -f "./../Mac/Release/Telegram.app/Contents/Frameworks/Updater" ]; then
  echo "Updater not found in Frameworks!"
  exit 1
fi

if [ ! -d "./../Mac/Release/Telegram.app/Contents/_CodeSignature" ]; then
  echo "Telegram signature not found!"
  exit 1
fi

cd ./../Mac/Release
temppath=`hdiutil attach -readwrite tsetup.dmg | awk -F "\t" 'END {print $3}'`
cp -R ./Telegram.app "$temppath/"
bless --folder "$temppath/" --openfolder "$temppath/"
hdiutil detach "$temppath"
hdiutil convert tsetup.dmg -format UDZO -imagekey zlib-level=9 -ov -o tsetup.$AppVersionStr.dmg
cd ./../../Telegram
cd ./../Mac/Release && ./Packer.app/Contents/MacOS/Packer -path Telegram.app -version $AppVersion && cd ./../../Telegram

if [ ! -d "./../Mac/Release/deploy/" ]; then
  mkdir "./../Mac/Release/deploy"
fi

echo "Copying Telegram.app and tmacupd$AppVersion to deploy/$AppVersionStr..";
mkdir "./../Mac/Release/deploy/$AppVersionStr"
mkdir "./../Mac/Release/deploy/$AppVersionStr/Telegram"
cp -r ./../Mac/Release/Telegram.app ./../Mac/Release/deploy/$AppVersionStr/Telegram/
mv ./../Mac/Release/Telegram.app.dSYM ./../Mac/Release/deploy/$AppVersionStr/
rm ./../Mac/Release/Telegram.app/Contents/MacOS/Telegram
rm ./../Mac/Release/Telegram.app/Contents/Frameworks/Updater
rm -rf ./../Mac/Release/Telegram.app/Contents/_CodeSignature
mv ./../Mac/Release/tmacupd$AppVersion ./../Mac/Release/deploy/$AppVersionStr/
mv ./../Mac/Release/tsetup.$AppVersionStr.dmg ./../Mac/Release/deploy/$AppVersionStr/tsetup.$AppVersionStr.dmg
echo "Version $AppVersionStr prepared!";

