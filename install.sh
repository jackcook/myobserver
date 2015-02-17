rm -rf Frameworks
mkdir Frameworks
wget "https://s3.amazonaws.com/thalmicdownloads/ios/Myo-iOS-SDK-0.4.0.zip" -O "myo.zip"
unzip myo.zip
rm -rf __MACOSX
mv Myo*/MyoKit.framework Frameworks/MyoKit.framework
rm -rf Myo*
rm myo.zip
pod install
