import std/[json, times]

import ./lowlevel

type
  GNetDevice* = object
    macAddr*: string
    ipAddr*: string
    sku*: string
  
  GController* = ref object
    transport: GoveeSocket
  
proc newGController*(localIp: string): GController =
  new(result)
  result.transport = newGoveeSocket(localIp)

proc newGController*(transport: GoveeSocket): GController =
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
  
  let start = epochTime()
  let deadline = epochTime() + float(timeout_ms) / 1000.0

  while epochTime() < deadline:
    var fds = @[ctrl.transport.getFd()]
    let remainingMs = int(max(0.0, (deadline - epochTime()) * 1000.0))

    if selectRead(fds, remainingMs) > 0:
      let n = ctrl.transport.recvFrom(data, address, port)
      
      let jdata = parseJson(data)
      let sku = jdata["msg"]["data"]["sku"].getStr
      let ip  = jdata["msg"]["data"]["ip"].getStr
      let mac = jdata["msg"]["data"]["device"].getStr

      if not skuModel.isNil and skuModel != "" and skuModel != sku:
        continue

      result.add(GNetDevice(
        macAddr:mac,
        ipAddr:ip,
        sku:sku
      ))