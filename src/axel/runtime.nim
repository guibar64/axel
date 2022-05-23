
when defined(onDevice):
 
  type
    PNimType = pointer
    TGenericSeq  = object
      len, reserved: int
    PGenericSeq = ptr TGenericSeq
    # len and space without counting the terminating zero:
    NimStringDesc = object
      len, reserved: int
      data: UncheckedArray[char]
    NimString = ptr NimStringDesc
  const
    seqShallowFlag = low(int)

  proc newObj(typ: PNimType, size: int): pointer {.compilerproc.} =
    alloc(size)

  proc rawNewStringNoInit(space: int): NimString {.compilerproc.} =
    var s = space
    if s < 7: s = 7
    result = cast[NimString](alloc(sizeof(TGenericSeq) + s + 1))
    result.reserved = s
    result.len = 0
    when defined(gogc):
      result.elemSize = 1

  proc rawNewString(space: int): NimString {.compilerproc.} =
    var s = space
    if s < 7: s = 7
    result = cast[NimString](sizeof(TGenericSeq) + s + 1)
    result.reserved = s
    result.len = 0
    when defined(gogc):
      result.elemSize = 1


    proc copyString(src: NimString): NimString {.compilerproc.} =
      if src != nil:
        if (src.reserved and seqShallowFlag) != 0:
          result = src
        else:
          result = rawNewStringNoInit(src.len)
          result.len = src.len
          copyMem(addr(result.data), addr(src.data), src.len + 1)
          #sysAssert((seqShallowFlag and result.reserved) == 0, "copyString")
          when defined(nimShallowStrings):
            if (src.reserved and strlitFlag) != 0:
              result.reserved = (result.reserved and not strlitFlag) or seqShallowFlag

  proc abort*() {.importc:"llvm.trap", cdecl, noreturn.}
  
  proc c_vprintf(frmt: cstring, arg: pointer): cint {.importc:"vprintf", cdecl, discardable.}

  proc rawOutput(s: string) =
    c_vprintf(s, nil)

  proc warnExceptions() =
    rawOutput("Warning: Exceptions not supported on device\n")

  proc nlvmRaise(e: ref Exception, ename: cstring) {.compilerproc, noreturn.} =
    warnExceptions()
    rawOutput("Unhandable Exeption: ")
    rawOutput(e.msg)
    rawOutput("\n")
    abort()

  proc nlvmReraise() {.compilerproc, noreturn.}  =
    warnExceptions()
    rawOutput("Error: cannot reraise\n")

  proc nlvmSetClosureException(e: ref Exception) {.compilerproc.} =
    warnExceptions()
    rawOutput("Attempt to set closure exception. Message: ")
    rawOutput(e.msg)
    rawOutput("\n")
    abort()
    
  proc nlvmGetCurrentException(): ref Exception {.compilerproc.} =
    warnExceptions()
    rawOutput("Attempt to set current exception. Message: ")
    rawOutput("\n")
    abort()
    

  proc nlvmBeginCatch(unwindArg: pointer) {.compilerproc, raises: [].} =
    warnExceptions()
    rawOutput("Attempt to begin catch\n")
    abort()

  proc nlvmEndCatch() {.compilerproc.} =
    warnExceptions()
    rawOutput("Attempt to end catch\n")
    abort()

  proc nlvmBadCleanup() {.compilerproc, noreturn.} =
    warnExceptions()
    rawOutput("Reached bad cleanup\n")
    abort()

  # needed by alloc0Impl

  proc c_malloc(size: csize_t): pointer {.importc:"malloc", cdecl.}

  proc c_calloc(nmemb, size: csize_t): pointer {.exportc: "calloc", cdecl.} =
    let size = nmemb*size
    result = c_malloc(size)
    zeroMem(result, size)

else:
  proc abort*() {.importc: "abort", cdecl, noreturn.}
