# Copyright (c) 2022 Guillaume Bareigts
# Licensed and distributed under the MIT license, see LICENSE

import macros
import ./private/mangling
template kerneltag*() {.pragma.}

macro kernel*(pdef: untyped) =
  ## marks a proc as a kernel
  if pdef.kind in {nnkProcDef, nnkFuncDef}:
    result = pdef
    result.addPragma(ident("kerneltag"))
    result.addPragma(newCall(ident "exportc", newLit kernelNameMangling(pdef)))
  else:
    error "'kernel' pragma only applies to proc definitions"
