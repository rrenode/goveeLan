import std/[json]
from socker import FoundDevice, Controller

type
  Percent = range[0..100]

  GBrightness* = Percent
  GTemp* = range[2000..9000]
  GColor* = object
    r*: int
    g*: int
    b*: int

  DeviceControl* = object
    device: FoundDevice
    controller: Controller
  
  DeviceStatus* = object
    on*: bool
    brightness*: GBrightness
    color*: GColor
    temp*: GTemp

proc status(d: DeviceControl) =
  discard 