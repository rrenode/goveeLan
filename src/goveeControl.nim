import std/[net, nativesockets, json, times, winlean]

const LOCAL_IP: string = "192.168.1.100"
const MCAST_IP: string = "239.255.255.250"
const MCAST_PORT: int = 4001
const LISTEN_PORT: int = 4002

