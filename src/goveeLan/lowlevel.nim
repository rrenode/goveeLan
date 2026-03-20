## Transport Layer
## 
## .. danger:: 
##      Do not treat this channel as secure against other hosts on the local network.
##    
##      This library uses Govee’s LAN UDP protocol. 
##      
##      Commands are sent as unauthenticated UDP JSON to device port 4003 per Govee's LAN docs. 
## 
## 
## 
## https://github.com/khchen/winim/blob/6fdee629140baa0d7060ddf86662457d11f50d35/winim/inc/winsock.nim#L1090
## https://learn.microsoft.com/en-us/windows/win32/winsock/ipproto-ip-socket-options
## https://www.ibm.com/docs/en/aix/7.3.0?topic=sockets-ip-multicasts
## https://github.com/multiplemonomials/multicast_expert

import std/[net, nativesockets, json, times, os]

const G_MCAST_IP = "239.255.255.250"
const G_MCAST_PORT = 4001
const G_LISTEN_PORT = 4002
const G_DEVICE_PORT = 4003

type
  ProtocolError* = object of CatchableError

  GNetClient* = ref object
    ## An IPv4 UDP socket wrapper for communicating with Govee devices
    ##    and sending to the Govee multicast group.
    ## 
    ## Domain: AF_INET (IPv4)
    ## SockType: SOCK_DGRAM (datagram-oriented communication)
    ## Protocol: IPPROTO_UDP (User ^^^^^^ Protocol)
    ## 
    ## Binds to port (and address if specified)
    ##
    sock: Socket
    closed: bool = true

proc newGNetClient*(localIp: string): GNetClient {.raises: [ref ValueError, ref OSError].} =
  new(result)
  try:
    result.sock = newSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
    result.sock.setSockOpt(OptReuseAddr, true)
    result.sock.bindAddr(Port(G_LISTEN_PORT), localIp)
  except OSError as e:
    raise newException(OSError,
      "newGNetClient failed for " & localIp & ":" & $G_LISTEN_PORT & ": " & e.msg)

proc close*(c: GNetClient) =
  if c != nil and not c.closed:
    c.sock.close()
    c.closed = true

proc sendTo*(
  g: GNetClient, ip: string, port: int, payload: string
) {.tags: [WriteIOEffect].} =
  net.sendTo(g.sock, $ip, Port(port), payload)

proc sendTo*(
  g: GNetClient, ip: string, port: int, payload: JsonNode
) {.tags: [WriteIOEffect].} =
  net.sendTo(g.sock, $ip, Port(port), $payload)

proc sendToDevice*[T: string | IpAddress](
  g: GNetClient, ip: T, payload: string
) {.tags: [WriteIOEffect].} =
  net.sendTo(g.sock, $ip, Port(G_DEVICE_PORT), payload)

proc sendToDevice*[T: string | IpAddress](
  g: GNetClient, ip: T, payload: JsonNode
) {.tags: [WriteIOEffect].} =
  g.sendTo(ip, G_DEVICE_PORT, $payload)

proc sendMCast*(g: GNetClient, payload: string) =
  g.sendTo(G_MCAST_IP, G_MCAST_PORT, payload)

proc sendMCast*(g: GNetClient, payload: JsonNode) =
  g.sendTo(G_MCAST_IP, G_MCAST_PORT, $payload)

proc recvFrom*(g: GNetClient, data: var string, ip: var string, port: var Port): int =
  g.sock.recvFrom(data, 4096, ip, port)

proc recvFrom*(g: GNetClient, data: var string, ip: var string, port: var string): int =
  ##
  var p: Port
  result = g.sock.recvFrom(data, 4096, ip, p)
  port = $p

proc getFd*(g: GNetClient): SocketHandle =
  g.sock.getFd()

proc selectRead*(readfds: var seq[SocketHandle], timeout = 500): int =
  nativesockets.selectRead(readfds, timeout)

proc selectRead*(g: GNetClient, timeout = 500): int =
  var fds = @[g.getFd()]
  nativesockets.selectRead(fds, timeout)