# Copyright (c) 2022 Guillaume Bareigts
# Licensed and distributed under the MIT license, see LICENSE

import std/macros


when defined(onDevice):
  # varagrs give wrong a number of argument error in the ptx
  proc c_vprintf(frmt: cstring, args: pointer): cint {.importc:"vprintf", cdecl, discardable.}

  # Apparently that's kinda what nvcc/clang do
  # printf(fmt, a, b, c) ->
  # pargs = object ( a, b, c)
  # vprintf(fmt, addr pargs)
  macro printf*(frmt: cstring, args: varargs[typed]): untyped =
    result = newStmtList()
    result.add nnkTypeSection.newTree()
    let tpargs = ident("Printf.args")
    result[^1].add nnkTypeDef.newTree(tpargs, newEmptyNode(), nnkObjectTy.newTree(newEmptyNode(), newEmptyNode(), nnkRecList.newTree()))
    var rec = result[^1][^1][^1][^1]
    let pargs = ident("printf.args")
    result.add nnkVarSection.newTree(
      newIdentDefs(pargs, tpargs)
    )
    for i in 0..<args.len:
      let field = ident("f" & $i)
      let oty = getType(args[i])
      let ty = if oty.typeKind() == ntyFloat32: ident("cdouble") else: oty  #nnkTypeOfExpr.newTree(args[i])
      rec.add nnkIdentDefs.newTree(field, ty, newEmptyNode())
      result.add newAssignment(nnkDotExpr.newTree(pargs, field), if oty.typeKind() == ntyFloat32: nnkCall.newTree(ty, args[i]) else: args[i])
    result.add newCall(bindSym("c_vprintf"), frmt, nnkAddr.newTree(pargs))

  proc echoString*(s: string) =
    discard c_vprintf(s.cstring, nil)
    discard c_vprintf("\n", nil)

else:
  proc printf*(frmt: cstring): cint {.importc, cdecl, varargs, discardable.}


when isMainModule:
  discard printf("%d %g %s\n", 1, 0.5, "chat")
