# Copyright (c) 2022 Guillaume Bareigts
# Licensed and distributed under the MIT license, see LICENSE

import macros, strutils

proc addS(s: string, result: var string) =
  case normalize(s)
  of "float", "float64", "cdouble":
    result.add "d"
  of "float32", "cfloat":
    result.add "f"
  of "int":
    result.add "i"
  of "int32", "cint":
    result.add "i32"
  of "int64":
    result.add "i64"
  of "clong":
    result.add "l"
  of "clonglong":
    result.add "L"
  of "uint":
    result.add 'u'
  of "cuint", "uint32":
    result.add "u32"
  of "culong":
    result.add "m"
  of "culonglong":
    result.add "U"
  of "uncheckedarray":
    result.add "A0"
  of "array":
    result.add "A"
  of "openarray":
    result.add "Ao"
  of "pointer":
    result.add 'P'
  else:
    result.add 'T'
    result.add s

proc addTypeCode(n: NimNode, result: var string) =
  case n.kind
  of nnkPtrTy:
    result.add "p"
  of nnkIdent:
    addS(n.strVal(), result)
  else:
    discard
  for c in n: addTypeCode(c, result)
  

proc kernelNameMangling*(p: NimNode): string {.compileTime.} =
  #TODO: proper name mangling (with typed AST?)
  result = "_K" & p.name().strVal
  for c in p[3]:
    if c.kind == nnkIdentDefs:
      let typ = c[^2]
      for i in 0..<c.len-2:
        result.add '_'
        addTypeCode(typ, result)



