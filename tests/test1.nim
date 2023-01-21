# Copyright (c) 2022 Guillaume Bareigts
# Licensed and distributed under the MIT license, see LICENSE

import axel/[device, math]

proc expcos(x: ptr UncheckedArray[float32], result: ptr UncheckedArray[float32]) {.kernel.} =
  let i = thisTeam()*numThreads() + thisThread()
  result[i] = exp(cos(x[i]))

proc vecAdd(a,b,c: ptr UncheckedArray[float32], n: cint)  {.kernel.} =
  let i = thisTeam()*numThreads() + thisThread()
  c[i] = a[i] + b[i]

proc prod(x,y: ptr UncheckedArray[int32], result: ptr UncheckedArray[int32]) {.kernel.} =
  let iret = thisTeam()*numTeams()
  let tid = thisThread()
  let sh = cast[Shared ptr UncheckedArray[int32]](getSharedMemBuffer())
  sh[iret + tid] = x[tid]*y[tid]
  threadBarrier()
  if thisThread() == 0:
    var res: int32 = 0
    for i in 0..<numThreads():
      res += sh[iret + i]
    result[iret] = res

when not defined(onDevice):
  # host side
  import std/random
  import axel/[devthreadpool, device_ptrs] 
  import axel/build_device_code

  proc tBase() =
    echo "tBase"
    proc check(a,b,c: seq[float32]) =
      for i in 0..<a.len:
        doAssert abs(c[i] - a[i] - b[i]) < 1.0e-6

    let n = 128*8
    var a,b,c = newSeq[float32](n)
    randomize(2727383)
    for i in 0..<a.len:
      a[i] = rand(1.0'f32)
      b[i] = rand(1.0'f32)

    var tp = newDevThreadpool()
    let da = createDeviceArrayPtr(a)
    let db = createDeviceArrayPtr(b)
    let dc = createDeviceArrayPtr[float32](c.len)
    let nth = 128
    let ntm = (n + nth - 1) div nth
    tp.setGrid(ntm, nth)
    sync tp.spawn vecAdd(!da, !db, !dc, cint n)
    sync c <- dc
    check(a,b,c)

    dealloc da
    dealloc db
    dealloc dc

  proc tMemUni() =
    echo "MemUni"
    proc check(a,b,c: ptr UncheckedArray[float32], n: int) =
      for i in 0..<n:
        doAssert abs(c[i] - a[i] - b[i]) < 1.0e-6


    # device allocations needs a context created first
    var tp = newDevThreadpool()

    let n = 128*8
    var a,b,c = createUniAddressArrayPtr[float32](n)
    randomize(2727383)
    for i in 0..<n:
      a[i] = rand(1.0'f32)
      b[i] = rand(1.0'f32)


    let nth = 128
    let ntm = (n + nth - 1) div nth
    tp.setGrid(ntm, nth)
    sync tp.spawn vecAdd(a, b, c, cint n)
    check(a,b,c,n)


    deallocUniAddressArrayPtr(a)
    deallocUniAddressArrayPtr(b)
    deallocUniAddressArrayPtr(c)

  proc tMath() =
    echo "Math"
    let
      nth = 128
      n = 8*nth

    var tp = newDevThreadpool()

    var a,c = newSeq[float32](n)
    randomize(2727383)
    for i in 0..<a.len:
      a[i] = rand(1.0'f32)

    let da = createDeviceArrayPtr(a)
    let dc = createDeviceArrayPtr[float32](c.len)
  
    sync tp.grid(n div nth, nth).spawn expcos(!da, !dc)
    sync c <- dc

    for i in 0..<a.len:
      let tv = exp(cos(a[i]))
      doAssert abs(c[i]-tv) < 1.0e-6*abs(tv), $ (i, a[i], c[i], tv)
    
    dealloc da
    dealloc dc

  proc tSharedMem() =
    echo "SharedMem"

    let n = 128

    var tp = newDevThreadpool()

    var x,y = newSeq[int32](n)
    randomize(2727383)
    var expected = 0'i32
    for i in 0..<n:
      x[i] = int32 rand(3793'i32)
      y[i] = int32 rand(3793'i32)
      expected += x[i]*y[i]

    let dx = createDeviceArrayPtr(x)
    let dy = createDeviceArrayPtr(y)
    let dres = createDeviceArrayPtr[int32](1)
    var res = [0'i32]

    sync tp.grid(1, n, sharedMemSize = n*sizeof(int)).spawn prod(!dx, !dy, !dres)
    sync res <- dres

    doAssert res[0] == expected, $(res[0], expected)
    
    dealloc dx
    dealloc dy
    dealloc dres

var globArray*: array[1024, int32]
proc setGlob(x: ptr UncheckedArray[int32]) {.kernel.} =
  let i = thisTeam()*numThreads() + thisThread()
  globArray[i] = x[i]
proc getGlob(x: ptr UncheckedArray[int32]) {.kernel.} =
  let i = thisTeam()*numThreads() + thisThread()
  x[i] = globArray[i]

when not defined(onDevice):
  import os
  import axel/[devthreadpool, build_device_code, device_ptrs]
  proc tGlobalMem() =
    echo "MemGlobal"
    proc check[T](a,b: ptr UncheckedArray[T], n: int) =
      for i in 0..<n:
        doAssert a[i] == b[i], $ (i, a[i], b[i])

    var tp = newDevThreadpool()

    let n = 1024
    var a,b = createUniAddressArrayPtr[int32](n)
    for i in 0..<n:
      a[i] = int32 (i+1)


    let nth = 128
    let ntm = (n + nth - 1) div nth
    tp.setGrid(ntm, nth)
    sync tp.spawn setGlob(a)
    sync tp.spawn getGlob(b)
    
    check(a, b, n)
    
    deallocUniAddressArrayPtr(a)
    deallocUniAddressArrayPtr(b)


when not defined(onDevice):
  tBase()
  tMemUni()
  tMath()
  tSharedMem()
  tGlobalMem()
