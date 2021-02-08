#!/bin/bash

# AppleALC stripdown | @cecekpawon Sun Jul 28 14:14:02 2019

#
# User defined
#

gCodecIdDec=283904146
gDeviceId=ALC892
gTarget=Release

#
# Global
#

gPlistBuddyCmd="/usr/libexec/plistbuddy -c"

WorkingDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BuildDir="${WorkingDir}/Build"
AppleALCDir="${WorkingDir}/AppleALC"
AppleALCBuildDir="${WorkingDir}/AppleALC/build"
MacKernelSDKDir="${WorkingDir}/AppleALC/MacKernelSDK"

cd "${WorkingDir}"

rm -rf ${BuildDir} && mkdir ${BuildDir}

ResetLocalRepo() {
  echo "Reset ${1}"

  cd "${1}"

  git fetch origin
  git reset --hard origin/master
  git pull
}

CloneResetLocalRepo() {
  url="${1}"
  dir="${2}"

  if [ ! -d "${dir}" ]; then
    git clone "${url}" "${dir}"
  else
    ResetLocalRepo "${dir}"
  fi
}

#
# Repo
#

CloneResetLocalRepo https://github.com/acidanthera/AppleALC "${AppleALCDir}"
CloneResetLocalRepo https://github.com/acidanthera/MacKernelSDK "${MacKernelSDKDir}"

cd "${WorkingDir}"

#
# Lilu
#

#if ! ls "${WorkingDir}"/Lilu-*-DEBUG.zip &> /dev/null; then
  json=$(curl -s https://api.github.com/repos/Acidanthera/Lilu/releases/latest)
  tag=$(echo "${json}" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  url=($(echo "${json}" | grep '"browser_download_url":' | sed -E 's/.*"([^"]+)".*/\1/'))

  for u in "${url[@]}"
  do
    if [[ "${u}" == *"DEBUG"* ]]; then
      un="Lilu-${tag}-DEBUG.zip"
      if [[ ! -f "${un}" ]]; then
        curl -L "${u}" -o "${un}"
      fi
      unzip -qo "${un}" -d "${AppleALCDir}"
      #break
    fi
    if [[ "${u}" == *"RELEASE"* ]]; then
      un="Lilu-${tag}-RELEASE.zip"
      if [[ ! -f "${un}" ]]; then
        curl -L "${u}" -o "${un}"
      fi
      unzip -qo "${un}" -d "${BuildDir}"
    fi
  done
#fi

#if [ ! -d "${AppleALCDir}/Lilu.kext" ]; then
#  unzip -qo "${WorkingDir}/Lilu-*-DEBUG.zip" -d "${AppleALCDir}"
#fi

#
# AppleALC
#

cd "${AppleALCDir}"

echo Edit AppleALC plist

gInfoPlist="Resources/PinConfigs.kext/Contents/Info.plist"
gHDAHardwareConfigResource="IOKitPersonalities:'HDA Hardware Config Resource'"
gHDAConfigDefault="$gHDAHardwareConfigResource:HDAConfigDefault"

$gPlistBuddyCmd "Add ':Tmp' dict" $gInfoPlist
$gPlistBuddyCmd "Copy :$gHDAHardwareConfigResource ':Tmp:$gHDAHardwareConfigResource" $gInfoPlist
$gPlistBuddyCmd "Add :Tmp:$gHDAConfigDefault array" $gInfoPlist

Configs=($(echo $($gPlistBuddyCmd "Print :$gHDAConfigDefault" $gInfoPlist -x) | grep -o "<dict>"))

let Cid=0
let NewCid=0

for i in "${Configs[@]}"
do
  CodecId=$($gPlistBuddyCmd "Print :$gHDAConfigDefault:${Cid}:CodecID" $gInfoPlist 2>&1)

  if [ $CodecId -eq $gCodecIdDec ]; then
    $gPlistBuddyCmd "Copy :$gHDAConfigDefault:${Cid} :Tmp:$gHDAConfigDefault:${NewCid}" $gInfoPlist
  fi

  let Cid++
  let NewCid++
done

$gPlistBuddyCmd "Delete :$gHDAConfigDefault" $gInfoPlist
$gPlistBuddyCmd "Copy :Tmp:$gHDAConfigDefault :$gHDAConfigDefault" $gInfoPlist
$gPlistBuddyCmd "Delete :Tmp" $gInfoPlist

if [ -d "Resources/$gDeviceId" ]; then
  Dirs=(Resources/*/)
  for Dir in "${Dirs[@]}"; do
    if [[ $Dir != *".kext"* && $Dir != *$gDeviceId* ]]; then
      rm -rf $Dir
    fi
  done
fi

echo Build AppleALC

xcodebuild -jobs 1 -configuration $gTarget #-mmacosx-version-min=10.15

echo Copy Build and cleanup directory

cp -R build/$gTarget/*.kext ${BuildDir}
rm -rf ${BuildDir}/*.dSYM
rm -rf Lilu.kext build *.md5 AppleALC/kern_resources.cpp

ResetLocalRepo "${AppleALCDir}"
ResetLocalRepo "${MacKernelSDKDir}"

cd "${WorkingDir}"
