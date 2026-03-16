import ./[midlevel, gsupport, models]

type
  GCommands* = enum
    gTurn, gBrightness, gColorwc, gStatus
  
  GCommandData* = object
    case cmd: GCommands
    of gTurn: state*: GPowerState
    of gBrightness: brightness*: GBrightness
    of gColorwc: clr*: GColor
    of gStatus: discard

  ## Device commands:
  ##    |-> turn        - On or off
  ##    |-> brightness  - value bound from 0 to 100
  ##    |-> colorwc     - RGB color setting and temperature
  ##    |-> status      - queries device status; getting states of above
  
  ## GDevice is an abstraction of device.
  GDevice* = ref object
    model: GDEVICES_ENUM
    macAddress: string
    netDevice: GNetDevice
    client: GClient

  ## Client's job is to provide a higher level interface for 
  ##    interacting and controlling Govee devices.
  ## It's more like a barrier between the midlevel controller 
  ##    and general use with some convenience built-in.
  ## Also acts as a sort of base type.
  ## 
  GClient* = ref object
    controller {. requiresInit.}: GController

var sharedController: GController

proc getSharedController(): GController =
  if sharedController.isNil:
    sharedController = GController()
  sharedController

proc newGClient*(): GClient =
  result = new(GCLient)
  result.controller = getSharedController()

proc dispatch(c: GClient, device: GDevice, data: GCommandData) =
  case data.cmd
  of gTurn:
    c.controller.turn(device.netDevice, bool(data.state))
  of gBrightness:
    discard
  of gColorwc:
    discard
  of gStatus:
    discard

# GDevice - field getters
proc model*(d: GDevice): GDEVICES_ENUM =
  d.model

proc macAddress*(d: GDevice): string =
  d.macAddress

proc dispatch(d: GDevice, data: GCommandData) =
  d.client.dispatch(d, data)

# GDrvice - procs
proc turnOn*(d: GDevice) =
  d.dispatch(GCommandData(cmd: gTurn, state: pOn))

proc turnOff*(d: GDevice) =
  d.dispatch(GCommandData(cmd: gTurn, state: pOff))