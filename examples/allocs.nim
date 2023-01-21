# Copyright (c) 2022 Guillaume Bareigts
# Licensed and distributed under the MIT license, see LICENSE

import axel/[device]

import std/mersenne
from std/math import sum

proc noyau(result: ptr UncheckedArray[int], n: int) {.kernel.} =
  let i = thisTeam()*numTeams() + thisThread()
  var rng = newMersenneTwister(uint32(i + 24455))
  let n = 10
  var x = cast[ptr UncheckedArray[int]](alloc(n*sizeof(int)))
  #var x = newSeq[int](n) # craches
  for i in 0..<n:
    x[i] = int(rng.getNum() mod 1024)

  result[i] = sum(toOpenArray(x, 0, n-1))
  dealloc(x)


when not defined(onDevice):
  # host side
  import axel/[devthreadpool, device_ptrs] 
  import axel/build_device_code

  let n = 32
  var tp = newDevThreadpool()
  var r = createUniAddressArrayPtr[int](n)

  sync tp.grid(1, n).spawn noyau(r, 10)

  echo $(toOpenArray(r, 0, n-1))

  deallocUniAddressArrayPtr(r)

