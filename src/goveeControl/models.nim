import std/[net]

type
  Controller* = object
    localIp*: string
    mcastIp*: string = "239.255.255.250"
    mcastPort*: int = 4001
    listenPort*: int = 4002
    devicePort*: int = 4003
    sock*: Socket

  FoundDevice* = object
    macAddr*: string
    ipAddr*: string
    sku*: string

  Percent = range[0..100]

  GBrightness* = Percent
  GTemp* = range[2000..9000]
  GColor* = object
    r*: int
    g*: int
    b*: int

  DeviceControl* = object
    device*: FoundDevice
    controller*: Controller
  
  DeviceStatus* = object
    on*: bool
    brightness*: GBrightness
    color*: GColor
    temp*: GTemp