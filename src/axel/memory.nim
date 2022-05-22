# Copyright (c) 2022 Guillaume Bareigts
# Licensed and distributed under the MIT license, see LICENSE

type
  Global* = object ## global address space
  Shared* = object ## group/team local address space
  Local* = object ## thread-local address space
  Constant* = object ## read-only address space



# 'Shared pointer' is not allowed


when defined(onDevice):

  proc getSharedMemBuffer*(): Shared ptr byte {.importc:"_nim_getSharedHeapRoot".}

else:
  proc getSharedMemBuffer*(): Shared ptr byte = discard

