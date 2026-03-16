import std/[net, nativesockets, json, times, winlean, os]

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

proc saveDevices*(devs: seq[FoundDevice], path: string) =
  var arr = newJArray()

  for d in devs:
    arr.add(%*{
      "mac": d.macAddr,
      "ip": d.ipAddr,
      "sku": d.sku
    })

  writeFile(path, $arr)

proc loadDevices*(path: string): seq[FoundDevice] =
  let j = parseJson(readFile(path))

  for n in j:
    result.add FoundDevice(
      macAddr: n["mac"].getStr,
      ipAddr: n["ip"].getStr,
      sku: n["sku"].getStr
    )

proc initController*(localIp: string, mcastIp: string = "239.255.255.250", mcastPort: int = 4001, listenPort: int = 4002, devicePort: int = 4003): Controller =
  result.localIp = localIp
  result.listenPort = listenPort
  result.mcastIp = mcastIp
  result.mcastPort = mcastPort
  result.devicePort = devicePort

  var socket = newSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
  socket.setSockOpt(OptReuseAddr, true)
  socket.bindAddr(Port(result.listenPort), result.localIp)

  let localAddr = parseIpAddress(result.localIp)
  var raw = localAddr.address_v4
  discard winlean.setsockopt(
    socket.getFd(),
    cint(IPPROTO_IP),
    cint(9),
    cast[pointer](addr raw),
    SockLen(sizeof(raw))
  )
  result.sock = socket

proc discover*(ctrl: Controller, skuModel: string = "", timeout_ms: int = 5000): seq[FoundDevice] =

  let payload = %*{
      "msg": {
          "cmd": "scan",
          "data": {
              "account_topic": "reserve"
          }
      }
  }

  net.sendTo(ctrl.sock, ctrl.mcastIp, Port(ctrl.mcastPort), $payload)

  let start = epochTime()

  var
    data: string = ""
    address: string = ""
    port: Port

  let deadline = epochTime() + float(timeout_ms) / 1000.0

  while epochTime() < deadline:
    var fds = @[ctrl.sock.getFd()]
    let remainingMs = int(max(0.0, (deadline - epochTime()) * 1000.0))

    if selectRead(fds, remainingMs) > 0:
      let n = ctrl.sock.recvFrom(data, 4096, address, port)
      #echo "R: ", n, " ", address, ":", port, " ", data
      let jdata = parseJson(data)
      let sku = jdata["msg"]["data"]["sku"].getStr
      let ip  = jdata["msg"]["data"]["ip"].getStr
      let mac = jdata["msg"]["data"]["device"].getStr

      if not skuModel.isNil and skuModel != "" and skuModel != sku:
        continue

      result.add(FoundDevice(
        macAddr:mac,
        ipAddr:ip,
        sku:sku
      ))

proc send*(ctrl: Controller, ip: string, payload: JsonNode) =
  net.sendTo(ctrl.sock, ip, Port(ctrl.devicePort), $payload)