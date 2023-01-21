import axel/device
import axel/device_arrays

proc vecAdd(a,b: Array[float32], c: Array[float32])  {.kernel.} =
  let i = thisTeam()*numThreads() + thisThread()
  if i < a.len:
    c[i] = a[i] + b[i]


when not defined(onDevice):
  # host code
  import std/random
  import axel/[devthreadpool, device_ptrs] 
  # Importing this module will trigger a recompilation by nlvm to generate
  # device code. Otherwise one could load independant device modules
  import axel/build_device_code

  # Initialize a context, loads device code
  var tp = newDevThreadpool()

  let n = 10_000
  # Allocates input/output arrays. With 'Unified' host and device buffers shares an address.
  var a,b,c = initArray[float32](n, kind = ArrayKind.Unified) 

  randomize(2727383)
  for i in 0..<n:
    a[i] = rand(1.0'f32)
    b[i] = rand(1.0'f32)

  let nth = 128
  let ntm = (n + nth - 1) div nth
  # launches a grid of ntm×nth kernels
  # Returns a 'FlowVar'.
  # 'sync' waits for the tasks to finish.
  sync tp.grid(ntm, nth).spawn vecAdd(a, b, c)

  #  check
  for i in 0..<n:
    doAssert abs(c[i] - (a[i] + b[i])) < 1.0e-6
