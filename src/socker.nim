import std/[net, nativesockets, json, times, winlean]

type
  Controller* = object
    localIp*: string
    mcastIp*: string = "239.255.255.250"
    mcastPort*: int = 4001
    listenPort*: int = 4002

  FoundDevice* = object
    macAddr*: string
    ipAddr*: string
    sku*: string

proc discover(ctrl: Controller, skuModel: string, timeout_ms: int): seq[FoundDevice] =

  var socket = newSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
  socket.setSockOpt(OptReuseAddr, true)
  socket.bindAddr(Port(ctrl.listenPort), ctrl.localIp)

  let localAddr = parseIpAddress(ctrl.localIp)
  var raw = localAddr.address_v4
  discard winlean.setsockopt(
    socket.getFd(),
    cint(IPPROTO_IP),
    cint(9),
    cast[pointer](addr raw),
    SockLen(sizeof(raw))
  )

  let payload = %*{
      "msg": {
          "cmd": "scan",
          "data": {
              "account_topic": "reserve"
          }
      }
  }

  net.sendTo(socket, ctrl.mcastIp, Port(ctrl.mcastPort), $payload)

  let start = epochTime()

  var
    data: string = ""
    address: string = ""
    port: Port

  let deadline = epochTime() + float(timeout_ms) / 1000.0

  while epochTime() < deadline:
    var fds = @[socket.getFd()]
    let remainingMs = int(max(0.0, (deadline - epochTime()) * 1000.0))

    if selectRead(fds, remainingMs) > 0:
      let n = socket.recvFrom(data, 4096, address, port)
      #echo "R: ", n, " ", address, ":", port, " ", data
      let jdata = parseJson(data)
      let sku = jdata["msg"]["data"]["sku"].getStr
      let ip  = jdata["msg"]["data"]["ip"].getStr
      let mac = jdata["msg"]["data"]["device"].getStr

      if not skuModel.isNil and skuModel != sku:
        continue

      result.add(FoundDevice(
        macAddr:mac,
        ipAddr:ip,
        sku:sku
      ))