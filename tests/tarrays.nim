import axel/device
import axel/device_arrays

proc vecAdd(a,b: Array[float32], c: Array[float32])  {.kernel.} =
  let i = thisTeam()*numThreads() + thisThread()
  if i < a.len:
    c[i] = a[i] + b[i]

when not defined(onDevice):
  import std/random
  import axel/[devthreadpool, device_ptrs] 
  import axel/build_device_code

  proc tvecAdd(kind: ArrayKind) =
    var tp = newDevThreadpool()

    let n = 100_000
    var a,b,c = initArray[float32](n, kind = kind) 

    randomize(2727383)
    for i in 0..<n:
      a[i] = rand(1.0'f32)
      b[i] = rand(1.0'f32)

    sync toDevice(a), toDevice(b)

    let nth = 128
    let ntm = (n + nth - 1) div nth
    sync tp.grid(ntm, nth).spawn vecAdd(a, b, c)
  
    sync toHost(c)

    # Sanity check
    for i in 0..<n:
      doAssert abs(c[i] - (a[i] + b[i])) < 1.0e-6
  
  tvecAdd(ArrayKind.Dual)
  tvecAdd(ArrayKind.Unified)
