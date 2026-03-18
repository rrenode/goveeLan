## https://learn.microsoft.com/en-us/windows/win32/winsock/ipproto-ip-socket-options
## https://github.com/khchen/winim/blob/6fdee629140baa0d7060ddf86662457d11f50d35/winim/inc/winsock.nim#L1090
##
import std/[winlean]

{.passL: "-lws2_32".}

type
  InAddr* {.importc: "struct in_addr", header: "<Ws2tcpip.h>".} = object
    s_addr*: uint32

  IpMreq* {.importc: "struct ip_mreq", header: "<Ws2tcpip.h>".} = object
    imr_multiaddr*: InAddr
    imr_interface*: InAddr

const
  IP_OPTIONS* = 1
  IP_HDRINCL* = 2
  IP_TOS* = 3
  IP_TTL* = 4
  IP_MULTICAST_IF* = 9
  IP_MULTICAST_TTL* = 10
  IP_MULTICAST_LOOP* = 11
  IP_ADD_MEMBERSHIP* = 12
  IP_DROP_MEMBERSHIP* = 13
  IP_DONTFRAGMENT* = 14
  IP_ADD_SOURCE_MEMBERSHIP* = 15
  IP_DROP_SOURCE_MEMBERSHIP* = 16
  IP_BLOCK_SOURCE* = 17
  IP_UNBLOCK_SOURCE* = 18
  IP_PKTINFO* = 19
  IP_RECEIVE_BROADCAST* = 22

proc inet_addr*(cp: cstring): uint32
  {.importc, header: "<winsock2.h>".}

proc setSockOpt*(s: SocketHandle; level, optname: int; optval: pointer): cint =
  winlean.setSockOpt(
    s=s,
    level=cint(level), # "protocol"?
    optname=cint(optname), # Option we want to change
    optval=cast[pointer](addr optval), # Value option is set to
    optlen=SockLen(sizeof(optval))
  )