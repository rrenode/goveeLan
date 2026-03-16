from scapy.all import ARP, Ether, srp
target_mac = "5c:e7:53:9a:2d:68".lower()

packet = Ether(dst="ff:ff:ff:ff:ff:ff") / ARP(pdst="192.168.1.0/24")
answered = srp(packet, timeout=2, verbose=0)[0]

for _, r in answered:
    print(r.psrc, r.hwsrc)
    if r.hwsrc.lower() == target_mac:
        print("FOUND:", r.psrc)