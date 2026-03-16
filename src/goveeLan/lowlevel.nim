import std/[net, nativesockets, json, times, winlean, os]

const G_MCAST_IP = "239.255.255.250"
const G_MCAST_PORT = 4001
const G_LISTEN_PORT = 4002
const G_DEVICE_PORT = 4003

type
  GoveeSocket* = ref object
    localIp: string
    sock: Socket

proc newGoveeSocket*(localIp: string): GoveeSocket =
  new(result)
  result.localIp = localIp

  var socket = newSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
  socket.setSockOpt(OptReuseAddr, true)
  socket.bindAddr(Port(G_MCAST_PORT), result.localIp)

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

proc close*(g: GoveeSocket) =
  if g != nil:
    g.sock.close()

proc sendTo*[T: string | IpAddress](
  g: GoveeSocket, ip: T, payload: string
) {.tags: [WriteIOEffect].} =
  net.sendTo(g.sock, $ip, Port(G_DEVICE_PORT), $payload)

proc sendTo*[T: string | IpAddress](
  g: GoveeSocket, ip: T, payload: JsonNode
) {.tags: [WriteIOEffect].} =
  g.sendTo(ip, $payload)

proc recvFrom*(g: GoveeSocket, data: var string, ip: var string, port: var Port): int =
  ##
  result = g.sock.recvFrom(data, 4096, ip, port)