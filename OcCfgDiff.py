#!/usr/bin/env python

# @cecekpawon - 8/9/2019 4:58:12 PM

# Trackdown changes of current and latest OpenCore config with Beyond Compare.
# https://github.com/acidanthera/OpenCorePkg
# https://www.scootersoftware.com/

import os, sys, subprocess, platform, plistlib, difflib

plSample = 'Sample.plist'
plConfig = 'config.plist'

plBCompWindows = os.path.join(os.environ.get('ProgramW6432', os.environ.get('ProgramFiles', '')), 'Beyond Compare 4', 'BComp.exe')
plBCompDarwin = os.path.join(os.sep, 'Applications', 'Beyond Compare.app', 'Contents', 'MacOS', 'bcomp')
plBCompLinux = os.path.join(os.sep, 'usr', 'bin', 'bcomp')
plBaseDir = os.path.dirname(os.path.abspath(__file__))
plDiffPath = os.path.join(plBaseDir, os.path.splitext(os.path.basename(__file__))[0]) + '.diff'

def toPlistFn(fn, sf=''):
  thisFn, thisExt = os.path.splitext(os.path.basename(fn))
  return (thisFn + sf + thisExt)

def toPlistSortedFn(fn):
  return toPlistFn(fn, '_sorted')

def writeSorted(fn):
  plFullFn = os.path.join(plBaseDir, toPlistFn(fn))

  if (os.path.exists(plFullFn)):
    if (sys.version_info[0] < 3):
      pl = plistlib.readPlist(plFullFn)
    else:
      with open(plFullFn, 'rb') as fp:
        pl = plistlib.load(fp)

    plSortedFullFn = os.path.join(plBaseDir, toPlistSortedFn(fn))

    if (sys.version_info[0] < 3):
      plistlib.writePlist(pl, plSortedFullFn)
    else:
      with open(plSortedFullFn, 'wb') as fp:
        plistlib.dump(pl, fp)

    if (os.path.exists(plSortedFullFn)):
      return plSortedFullFn

plSortedSampleFullFn = writeSorted(plSample)

if (plSortedSampleFullFn):
  plSortedConfigFullFn = writeSorted(plConfig)

  if (plSortedConfigFullFn):
    if (platform.system() == 'Windows'):
      plBComp = plBCompWindows
    elif (platform.system() == 'Darwin'):
      plBComp = plBCompDarwin
    elif (platform.system() == 'Linux'):
      plBComp = plBCompLinux
    else:
      plBComp = ''

    if (os.path.exists(plBComp)):
      subprocess.Popen([plBComp, plSortedConfigFullFn, plSortedSampleFullFn])
    else:
      with open(plSortedConfigFullFn) as fp1, open(plSortedSampleFullFn) as fp2:
        diff = difflib.ndiff(fp1.readlines(), fp2.readlines())
      with open(plDiffPath, 'w') as fp:
        for line in diff:
          fp.write(line)
