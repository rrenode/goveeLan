## .. importdoc:: midlevel.nim
import std/[tables, sequtils]
import ./[midlevel, gsupport, models]

type
  ## Device commands:
  ##    |-> turn        - On or off
  ##    |-> brightness  - value bound from 0 to 100
  ##    |-> colorwc     - RGB color setting and temperature (split into two)
  ##    |-> status      - queries device status; getting states of above

  GCommands = enum
    gTurn, gBrightness, gColor, gTemp, gStatus
  
  GCommandData = object
    case cmd: GCommands
    of gTurn: state: GPowerState
    of gBrightness: brightness: GBrightness
    of gColor: clr: GColor
    of gTemp: t: GTemperature
    of gStatus: discard
  
  GDevice* = ref object
    ## GDevice is the higher level abstraction of GNetDevice.
    model: GDEVICES_ENUM
    macAddress: string
    netDevice: GNetDevice
    attached: bool
    client: GClient

  GClient* = ref object
    ## **Constructor:** [newGClient]
    ## 
    ## Higher level interface of [GController] 
    ##    interacting and controlling Govee devices.
    ## 
    ## A GDevice can only be attached to one client.
    ## 
    ## 
    ## | procs                   | desc                              |
    ## | ----------------------- | --------------------------------- |
    ## | [discoverDevices]       | Scan the network for devices      |
    ## | [discoverAttachDevices] | Like avove, but also attaches them to the client |
    ## | [attachDevice]          | Attach [GDevice] to the client |
    ## | [attachDevices]         | Attach a seq of [GDevice]'s to client |
    ## | [listDevices]           | Lists attached devices |
    ## 
    devices: Table[string, GDevice]
    controller {. requiresInit.}: GController

proc newGDevice(gd: GNetDevice): GDevice

var sharedController: GController

proc getSharedController(): GController =
  if sharedController.isNil:
    sharedController = newGController()
  sharedController

proc newGClient*(): GClient =
  result = GClient(
    devices: initTable[string, GDevice](),
    controller: getSharedController()
  )

proc dispatch(c: GClient, device: GDevice, data: GCommandData) =
  ## Dispatch command to device and expect no return.
  ## Status request does nothing here.
  case data.cmd
  of gTurn:
    c.controller.turn(device.netDevice, bool(data.state))
  of gBrightness:
    c.controller.brightness(device.netDevice, data.brightness)
  of gColor:
    c.controller.color(device.netDevice, data.clr.r, data.clr.g, data.clr.b)
  of gTemp:
    c.controller.temperature(device.netDevice, data.t)
  of gStatus:
    raise newException(ValueError, "gStatus is a query, not a dispatchable command")

proc attachDevice*(c: GClient, d: GDevice) =
  ## Attach a device to a client
  if c.devices.hasKey(d.macAddress):
    let existing = c.devices[d.macAddress]
    if existing == d:
      return
    else:
      raise newException(ValueError, "Duplicate device attempt with MAC: " & d.macAddress)
  else:
    c.devices[d.macAddress] = d
    d.client = c
    d.attached = true

proc detachDevice*(c: GClient, d: GDevice) =
  ## Detach the device from its client
  ## 
  ## GDevice will lose function.
  if c.devices.hasKey(d.macAddress):
    let existing = c.devices[d.macAddress]
    if existing != d:
      # A device with the same MAC address already exists... duplicate device!
      raise newException(ValueError, "Device mismatch!")
    c.devices.del(d.macAddress)
    d.attached = false
    d.client = nil

proc attachDevices*(c: GClient, devices: seq[GDevice]) =
  ## Register many devices in the client.
  for d in devices:
    c.attachDevice(d)

proc listDevices*(c: GClient): seq[GDevice] =
  ## Lists attached devices
  return toSeq(c.devices.values)

proc discoverDevices*[T: string | GDEVICES_ENUM](c: GClient, skuModel: T = ""): seq[GDevice] =
  ## Discover Govee devices on Lan.
  ## 
  ## INFO:
  ##  \ The resulting GDevices cannot be controlled. 
  ##   \ They must be attached to a client
  let netDevices = c.controller.discover($skuModel)
  for d in netDevices:
    result.add(newGDevice(d))

proc discoverAttachDevices*[T: string | GDEVICES_ENUM](c: GClient, skuModel: T = ""): seq[GDevice] =
  ## Discover Govee devices on Lan and attach them to the client.
  ## Returns a seq of the newly attached devices.
  let netDevices = c.controller.discover($skuModel)
  for nd in netDevices:
    if not isSupported(nd.sku):
      continue
    let d = newGDevice(nd)
    c.attachDevice(d)
    result.add(d)

# GDevice - Constructor
proc newGDevice(gd: GNetDevice): GDevice =
  new(result)
  result.model = skuToEnum(gd.sku)
  result.macAddress = gd.macAddr
  result.netDevice = gd

# GDevice - field getters
proc model*(d: GDevice): GDEVICES_ENUM =
  skuToEnum(d.netDevice.sku)

proc macAddress*(d: GDevice): string =
  d.netDevice.macAddr

proc attached*(d: GDevice): bool =
  not d.client.isNil

proc status*(d: GDevice): GDeviceStatus =
  if d.client.isNil:
    raise newException(ValueError, "Device is not attached to a client")
  let j = d.client.controller.status(d.netDevice)
  result = j.to(GDeviceStatus)

# GDevice - procs stuffs
proc dispatch(d: GDevice, data: GCommandData) =
  if d.client.isNil:
    raise newException(ValueError, "Device is not attached to a client")
  d.client.dispatch(d, data)

proc turnOn*(d: GDevice) =
  d.dispatch(GCommandData(cmd: gTurn, state: pOn))

proc turnOff*(d: GDevice) =
  d.dispatch(GCommandData(cmd: gTurn, state: pOff))

proc setBrightness*(d: GDevice, val: GBrightness) =
  d.dispatch(GCommandData(cmd: gBrightness, brightness: val))

proc setColor*(d: GDevice, clr: GColor) =
  d.dispatch(GCommandData(cmd: gColor, clr: clr))

proc setTemperature*(d: GDevice, temp: GTemperature) =
  d.dispatch(GCommandData(cmd: gTemp, t: temp))

# GDevice - std compat
proc `$`*(d: GDevice): string =
  "GDevice(model=" & $d.model & ", mac=" & macAddress(d) & ")"