import axel/device
import axel/device_arrays

proc vecAdd(a,b: openArray[float32], c: Array[float32])  {.kernel.} =
  let i = thisTeam()*numThreads() + thisThread()
  if i < a.len:
    c[i] = a[i] + b[i]

when not defined(onDevice):
  import std/random
  import axel/[devthreadpool, device_ptrs] 
  import axel/build_device_code

  proc tvecAdd() =
    var tp = newDevThreadpool()

    let n = 11_000
    var a,b,c = initArray[float32](n, kind = ArrayKind.Unified) 

    randomize(2727383)
    for i in 0..<n:
      a[i] = rand(1.0'f32)
      b[i] = rand(1.0'f32)

    let nth = 128
    let ntm = (n + nth - 1) div nth
    sync tp.grid(ntm, nth).spawn vecAdd(a.toOpenArray(0, n-1), b.toOpenArray(0, n-1), c)
  
    # Sanity check
    for i in 0..<n:
      doAssert abs(c[i] - (a[i] + b[i])) < 1.0e-6
  
  tvecAdd()
