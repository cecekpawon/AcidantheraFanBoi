#!/bin/bash

# Acidanthera download | @cecekpawon Sun Jul 28 14:14:02 2019

#
# User defined
#

gTarget=DEBUG
gTarget=RELEASE
gDebug=1
gDebug=0

# https://github.com/acidanthera

# gDebug sorted results

gProgs=(
#AirportBrcmFixup
#AppleALC
#AppleSupportPkg
#AptioFixPkg
#audk
#BrcmPatchRAM
#BrightnessKeys
#BT4LEContinuityFixup
#bugtracker
#CPUFriend
#CpuTscSync
#DebugEnhancer
#dmidecode
#DuetPkg
#EfiPkg
#gfxutil
#HibernationFixup
IntelMausi
#IOJones
Lilu
#mac-efi-firmware
#MaciASL
#MacInfoPkg
#MacKernelSDK
#macserial
#NVMeFix
#OcBinaryData
#ocbuild
#OcLegacyPkg
#OcSupportPkg
#onyx-the-black-cat
#OpenCorePkg
#OpenCoreShell
#RestrictEvents
#RTCMemoryFixup
#Shiki
VirtualSMC
#VoodooInput
#VoodooPS2
#WhateverGreen
)

#
# Global
#

WorkingDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#
# !
#

GetRepos () {
  res=$1
  json=$(curl -s "https://api.github.com/orgs/acidanthera/repos?sort=updated&per_page=$res")
  name=($(echo "${json}" | grep '"full_name":' | sed -E 's/.*"([^"]+)".*/\1/'))

  for n in "${name[@][0]}"
  do
    fname=$(basename "${n}")
    echo "${fname}"
  done
}

GetProg () {
  prog=$1
  json=$(curl -s "https://api.github.com/repos/Acidanthera/$prog/releases/latest")
  tag=$(echo "${json}" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  url=($(echo "${json}" | grep '"browser_download_url":' | sed -E 's/.*"([^"]+)".*/\1/'))

  for u in "${url[@]}"
  do
    fname=$(basename "${u}")
    if [[ "${u}" == *"${gTarget}"* ]]; then
      label=exist
      if [[ ! -f "${fname}" ]]; then
        label=download
        curl -L -C - "${u}" -o "${fname}"
      fi
      echo " --> ${fname} (${label})"
    fi
  done
}

cd "${WorkingDir}"

if [[ ${gDebug} -ne 0 ]]; then
  GetRepos 100
  exit
fi

for label in "${gProgs[@]}"
do
  echo "${label}"
  GetProg "${label}"
done

cd "${WorkingDir}"
