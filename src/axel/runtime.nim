
when defined(onDevice):

  proc abort*() {.importc: "llvm.trap", cdecl, noreturn.}

  proc c_vprintf(frmt: cstring, arg: pointer): cint {.importc: "vprintf", cdecl, discardable.}

  proc rawOutput*(s: string) =
    c_vprintf(s, nil)

  proc warnExceptions() =
    rawOutput("Warning: Exceptions not supported on device\n")

  proc nlvmRaise(e: ref Exception) {.compilerproc, noreturn.} =
    warnExceptions()
    rawOutput("Unhandable Exeption: ")
    rawOutput(e.msg)
    rawOutput("\n")
    abort()

  proc nlvmReraise() {.compilerproc, noreturn.} =
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

  proc nlvmEHPersonality(
      version: cint,
      actions: cint,
      exceptionClass: uint64,
      unwindException: pointer,
      ctx: pointer): cint {.compilerproc.} =
    warnExceptions()
    rawOutput("Reached EH personality\n")
    abort()

else:
  proc abort*() {.importc: "abort", cdecl, noreturn.}
