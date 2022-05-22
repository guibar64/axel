# Copyright (c) 2022 Guillaume Bareigts
# Licensed and distributed under the MIT license, see LICENSE 

when defined(cuda):
  proc threadIdxX*(): int32 {.importc: "llvm.nvvm.read.ptx.sreg.tid.x".}
  proc threadIdxY*(): int32 {.importc: "llvm.nvvm.read.ptx.sreg.tid.y".}
  proc threadIdxZ*(): int32 {.importc: "llvm.nvvm.read.ptx.sreg.tid.z".}
  proc blockDimX*(): int32 {.importc: "llvm.nvvm.read.ptx.sreg.ntid.x".}
  proc blockDimY*(): int32 {.importc: "llvm.nvvm.read.ptx.sreg.ntid.y".}
  proc blockDimZ*(): int32 {.importc: "llvm.nvvm.read.ptx.sreg.ntid.z".}
  proc blockIdxX*(): int32 {.importc: "llvm.nvvm.read.ptx.sreg.ctaid.x".}
  proc blockIdxY*(): int32 {.importc: "llvm.nvvm.read.ptx.sreg.ctaid.y".}
  proc blockIdxZ*(): int32 {.importc: "llvm.nvvm.read.ptx.sreg.ctaid.z".}
  proc gridDimX*(): int32 {.importc: "llvm.nvvm.read.ptx.sreg.nctaid.x".}
  proc gridDimY*(): int32 {.importc: "llvm.nvvm.read.ptx.sreg.nctaid.y".}
  proc gridDimZ*(): int32 {.importc: "llvm.nvvm.read.ptx.sreg.nctaid.z".}
  proc warpSize*(): int32 {.importc:"llvm.nvvm.read.ptx.sreg.warpsize".}

  proc threadBarrier*() {.importc: "llvm.nvvm.barrier0".}

else:
  proc threadIdxX*(): int32 = 0
  proc threadIdxY*(): int32 = 0
  proc threadIdxZ*(): int32 = 0
  proc blockDimX*(): int32 = 1 
  proc blockDimY*(): int32 = 1
  proc blockDimZ*(): int32 = 1
  proc blockIdxX*(): int32 = 0
  proc blockIdxY*(): int32 = 0
  proc blockIdxZ*(): int32 = 0
  proc gridDimX*(): int32 = 1
  proc gridDimY*(): int32 = 1
  proc gridDimZ*(): int32 = 1
  proc warpSize*(): int32 = 1
  
  proc threadBarrier*() = discard


type
  ThreadIdx* = object
  NumThreads* = object
  TeamIdx* = object
  NumTeams* = object

template x*(_: typedesc[ThreadIdx]): int32 = threadIdxX()
template y*(_: typedesc[ThreadIdx]): int32 = threadIdxY()
template z*(_: typedesc[ThreadIdx]): int32 = threadIdxZ()
template x*(_: typedesc[NumThreads]): int32 = blockDimX()
template y*(_: typedesc[NumThreads]): int32 = blockDimY()
template z*(_: typedesc[NumThreads]): int32 = blockDimZ()
template x*(_: typedesc[TeamIdx]): int32 = blockIdxX()
template y*(_: typedesc[TeamIdx]): int32 = blockIdxY()
template z*(_: typedesc[TeamIdx]): int32 = blockIdxZ()
template x*(_: typedesc[NumTeams]): int32 = gridDimX()
template y*(_: typedesc[NumTeams]): int32 = gridDimY()
template z*(_: typedesc[NumTeams]): int32 = gridDimZ()

template numThreads*(): int32 = blockDimX()

template thisThread*(): int32 = threadIdxX()

template numTeams*(): int32 = gridDimX()

template thisTeam*(): int32 = blockIdxX()
