# Copyright (c) 2022 Guillaume Bareigts
# Licensed and distributed under the MIT license, see LICENSE

import ./cuda

type
  CudaError* = object of ValueError
    code*: CUresult

proc check*(err: CUresult) =
  if err != CUDA_SUCCESS:
    var pStr: cstring
    cuGetErrorString(err, addr pStr)
    raise newException(CudaError, if pStr == nil: "(unkwon error)" else: $pStr)

check cuInit(0)
