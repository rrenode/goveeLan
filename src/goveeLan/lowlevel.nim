## Transport Layer
## 
## .. danger:: 
##      Do not treat this channel as secure against other hosts on the local network.
##    
##      This library uses Govee’s LAN UDP protocol. 
##      
##      Commands are sent as unauthenticated UDP JSON to device port 4003 per Govee's LAN docs. 
## 
## # Design Notes
## 
##      Communication with the MCAST group versus the devices is technically 
##          seperate concerns; though related. The Govee device discovery is 
##          send-reply. All of the device commands, excluding the status 
##          command, do not send back return data.
## 
##      GMulticast Socket
##        \|- Domain: AF_INET (IPv4)
##        \|- SockType: SOCK_DGRAM (datagram-oriented communication)
##        \|- Protocol: IPPROTO_UDP (User ^^^^^^ Protocol)
##        \|- Is address/port bound
##        \|- Joins MCast Group (IP_ADD_MEMBERSHIP)
##        \|- Can send and recieve
##      
##      GUnicast Socket
##        \|- Domain: AF_INET (IPv4)
##        \|- SockType: SOCK_DGRAM (datagram-oriented communication)
##        \|- Protocol: IPPROTO_UDP (User ^^^^^^ Protocol)
##        \|- Is not bound
##        \|- Doesn't care to join the MCast group
##        \|- Can send and recieve
## 
## 
## https://github.com/khchen/winim/blob/6fdee629140baa0d7060ddf86662457d11f50d35/winim/inc/winsock.nim#L1090
## https://learn.microsoft.com/en-us/windows/win32/winsock/ipproto-ip-socket-options
## https://www.ibm.com/docs/en/aix/7.3.0?topic=sockets-ip-multicasts
## https://github.com/multiplemonomials/multicast_expert

import std/[net, nativesockets, json, times, os]

when defined(windows):
  import winlean

const G_MCAST_IP = "239.255.255.250"
const G_MCAST_PORT = 4001
const G_LISTEN_PORT = 4002
const G_DEVICE_PORT = 4003

type
  ProtocolError* = object of CatchableError

  GoveeSocket* = ref object
    localIp: string
    sock: Socket

proc newGoveeSocket*(localIp: string): GoveeSocket =
  new(result)
  result.localIp = localIp

  var socket = newSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
  doAssert socket != nil, "newSocket failed"

  socket.setSockOpt(OptReuseAddr, true)
  socket.bindAddr(Port(G_LISTEN_PORT), result.localIp)

  let localAddr = parseIpAddress(result.localIp)
  var raw = localAddr.address_v4
  discard winlean.setsockopt(
    socket.getFd(),
    cint(IPPROTO_IP),
    cint(9), # TODO: This only works for Windows
    cast[pointer](addr raw),
    SockLen(sizeof(raw))
  )
  result.sock = socket
  doAssert result.sock != nil, "result.sock not set"

proc close*(g: GoveeSocket) =
  if g != nil:
    g.sock.close()

proc sendTo*(
  g: GoveeSocket, ip: string, port: int, payload: string
) {.tags: [WriteIOEffect].} =
  net.sendTo(g.sock, $ip, Port(port), payload)

proc sendTo*(
  g: GoveeSocket, ip: string, port: int, payload: JsonNode
) {.tags: [WriteIOEffect].} =
  net.sendTo(g.sock, $ip, Port(port), $payload)

proc sendToDevice*[T: string | IpAddress](
  g: GoveeSocket, ip: T, payload: string
) {.tags: [WriteIOEffect].} =
  net.sendTo(g.sock, $ip, Port(G_DEVICE_PORT), payload)

proc sendToDevice*[T: string | IpAddress](
  g: GoveeSocket, ip: T, payload: JsonNode
) {.tags: [WriteIOEffect].} =
  g.sendTo(ip, G_DEVICE_PORT, $payload)

proc sendMCast*(g: GoveeSocket, payload: string) =
  g.sendTo(G_MCAST_IP, G_MCAST_PORT, payload)

proc sendMCast*(g: GoveeSocket, payload: JsonNode) =
  g.sendTo(G_MCAST_IP, G_MCAST_PORT, $payload)

proc recvFrom*(g: GoveeSocket, data: var string, ip: var string, port: var Port): int =
  g.sock.recvFrom(data, 4096, ip, port)

proc recvFrom*(g: GoveeSocket, data: var string, ip: var string, port: var string): int =
  ##
  var p: Port
  result = g.sock.recvFrom(data, 4096, ip, p)
  port = $p

proc getFd*(g: GoveeSocket): SocketHandle =
  g.sock.getFd()

proc selectRead*(readfds: var seq[SocketHandle], timeout = 500): int =
  nativesockets.selectRead(readfds, timeout)

proc selectRead*(g: GoveeSocket, timeout = 500): int =
  var fds = @[g.getFd()]
  nativesockets.selectRead(fds, timeout)