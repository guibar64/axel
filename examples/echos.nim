import std/algorithm
import axel/device

proc noyau() {.kernel.} =
  let idx = thisTeam()*numTeams() + thisThread()
  echo "Hello from ", idx

when not defined(onDevice):
  # host side
  import axel/devthreadpool
  import axel/build_device_code

  let n = 8
  var tp = newDevThreadpool()

  sync tp.grid(1, n).spawn noyau()
