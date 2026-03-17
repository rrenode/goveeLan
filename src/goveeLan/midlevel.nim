import std/[json, times]
from std/net import getPrimaryIPAddr, `$`

import ./lowlevel

type
  GNetDevice* = ref object
    macAddr*: string
    ipAddr*: string
    sku*: string
  
  GController* = ref object
    transport: GoveeSocket

# Contstructors
proc newGController*(localIp: string = ""): GController
proc newGController*(transport: GoveeSocket): GController

# GController Procs
proc discover*(ctrl: GController, skuModel: string = "", timeout_ms: int = 5000): seq[GNetDevice]

proc turn*(ctrl: GController, d: GNetDevice, on: bool)
proc brightness*(ctrl: GController, d: GNetDevice, val: int)


proc newGController*(localIp: string = ""): GController =
  ## Creates a controller with its own transport socket.
  ##
  ## This is suitable when this controller is the only instance using
  ## Govee LAN communication on the given local interface.
  ##
  ## On some platforms, notably Windows, multiple controllers cannot
  ## reliably bind separate sockets to the discovery port (4002) on
  ## the same local IP. In those cases, controllers must share a
  ## single `GoveeSocket`.
  ## 
  ## If you need to share a transport between multiple controllers,
  ## use `newGController(transport: GoveeSocket)` instead.
  ## 
  var lanAddr = localIp
  if lanAddr == "":
    lanAddr = $getPrimaryIPAddr()
  new(result)
  result.transport = newGoveeSocket(lanAddr)

proc newGController*(transport: GoveeSocket): GController =
  ## Use an existing transport socket.
  ##
  ## Note:
  ## Govee LAN discovery requires a UDP listener on port 4002.
  ##  If multiple sockets are bound to the same port, the OS may
  ##    deliver packets to only one of them. 
  ## Sharing a single GoveeSocket between controllers is 
  ##    therefore recommended.
  ## 
  new(result)
  result.transport = transport

proc discover*(ctrl: GController, skuModel: string = "", timeout_ms: int = 5000): seq[GNetDevice] =
  let payload = %*{
      "msg": {
          "cmd": "scan",
          "data": {
              "account_topic": "reserve"
          }
      }
  }

  ctrl.transport.sendMCast(payload)

  var 
    data: string = ""
    address: string = ""
    port: string = ""
  
  let deadline = epochTime() + float(timeout_ms) / 1000.0

  while epochTime() < deadline:
    var fds = @[ctrl.transport.getFd()]
    let remainingMs = int(max(0.0, (deadline - epochTime()) * 1000.0))

    if selectRead(fds, remainingMs) > 0:
      let n = ctrl.transport.recvFrom(data, address, port)
      if n <= 0:
        raise newException(IOError, "No response received")
      let jdata = parseJson(data)
      let sku = jdata["msg"]["data"]["sku"].getStr
      let ip  = jdata["msg"]["data"]["ip"].getStr
      let mac = jdata["msg"]["data"]["device"].getStr

      if skuModel != "" and skuModel != sku:
        continue
      
      result.add(GNetDevice(
        macAddr:mac,
        ipAddr:ip,
        sku:sku
      ))
  
proc turn*(ctrl: GController, d: GNetDevice, on: bool) =
  ## For turn, either 0 for off or 1 for on
  let val = if on: 1 else: 0
  let payload = %*{
    "msg": {
      "cmd": "turn",
      "data": {
        "value": val
      }
    }
  }
  ctrl.transport.sendToDevice(d.ipAddr, payload)

proc brightness*(ctrl: GController, d: GNetDevice, val: int) =
  ## For brightness, Govee wants an integer bound(0, 100)
  let payload = %*{
    "msg": {
      "cmd": "brightness",
      "data": {"value": val}
    }
  }
  ctrl.transport.sendToDevice(d.ipAddr, payload)

proc temperature*(ctrl: GController, d: GNetDevice, val: int) =
  ## Same as color using `colorwc` command, but color is 
  ##    ignored by Govee when temp is set.
  ## Govee wants an integer bound(2000, 9000) representing kelvin.
  let payload = %*{
      "msg":{
          "cmd":"colorwc",
          "data":{
          "color":{
              "r":0,
              "g":0,
              "b":0
          },
          "colorTemInKelvin":val
          }
      }
  }
  ctrl.transport.sendToDevice(d.ipAddr, payload)

proc color*(ctrl: GController; d: GNetDevice; r, g, b: int) =
  ## Same as color using `colorwc` command, but color is 
  ##    ignored by Govee when temp is set.
  ## Govee wants an integer bound(2000, 9000) representing kelvin.
  let payload = %*{
      "msg":{
          "cmd":"colorwc",
          "data":{
          "color":{
              "r":r,
              "g":g,
              "b":b
          },
          "colorTemInKelvin":0
          }
      }
  }
  ctrl.transport.sendToDevice(d.ipAddr, payload)

proc status*(ctrl: GController; d:GNetDevice, timeout_ms: int = 500): JsonNode =
  let payload = %*{
    "msg": {
      "cmd": "devStatus",
      "data": {}
    }
  }
  ctrl.transport.sendToDevice(d.ipAddr, payload)

  var
    data = ""
    address = ""
    port = ""

  var fds = @[ctrl.transport.getFd()]
  if selectRead(fds, timeout_ms):
    raise newException(IOError, "Timed out waiting for device status response")

  let n = ctrl.transport.recvFrom(data=data, ip=address, port=port)
  if n <= 0:
    raise newException(IOError, "No response received")

  result = parseJson(data)
