# Copyright (c) 2022 Guillaume Bareigts
# Licensed and distributed under the MIT license, see LICENSE

const nlvmPath {.strdefine, used.} = "nlvm"

const deviceKind {.strdefine, used.} = "cuda"

const deviceArch {.strdefine, used.} = ""

const deviceDebugInfo {.booldefine, used.} = false

when not defined(onDevice):
  import std/macros
  import std/compilesettings # the only way to get projectFull ?

  proc compileDeviceCode(): string =
    let src = querySetting(projectFull)
    let ext = when deviceKind == "cuda": ".ptx" else: ".o"
    let dest = src & ext
    # default version 37, otherwise libdevice is not compiled
    let mpcu = " --nlvm.cpu='" & (when deviceArch == "": (when deviceKind == "cuda":  "sm_37" else: "") else: deviceArch) & "' "
    let triple = when deviceKind == "cuda": " --nlvm.target=nvptx64-nvidia-cuda " else: " "
    let relType = when defined(danger): "-d:danger " elif defined(release): "-d:release " else: ""
    let dbgInfo = when deviceDebugInfo: "-g " else: ""
    let nimcmd = nlvmPath & " c -d:onDevice " & relType & dbgInfo & triple & mpcu &
      " --gc:none --noMain --noLinking -d:useMalloc  -d:noSignalHandler -o:" &
      dest & " " & src
    echo nimcmd
    let (output, exc) = gorgeEx(nimcmd)
    echo output
    if exc == 0:
      result = staticRead(dest)
    else:
      error("compilation of device code failed!")

  const theGeneratedDeviceCode* = compileDeviceCode()
