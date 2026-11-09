start_all()
router.wait_for_unit("multi-user.target")
target.wait_for_unit("multi-user.target")
target.wait_for_unit("echo-server.service")
router.wait_for_unit("user-tun-mihomo.service")
router.wait_for_unit("user-tun-singbox.service")

print("=== [diag] ip rule (auto_route) ===")
print(router.succeed("ip rule show"))
print("=== [diag] ip route table all ===")
print(router.succeed("ip -4 route show table all"))
print("=== [diag] sing-box journal ===")
print(router.succeed("journalctl -u user-tun-singbox.service -n 60 --no-pager || true"))

echodns = '''import socket, sys
host, port = sys.argv[1], int(sys.argv[2])
ai = socket.getaddrinfo(host, port, socket.AF_INET, socket.SOCK_STREAM)
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.settimeout(10)
s.connect(ai[0][4])
s.sendall(b'domain-hello')
x = s.recv(4096)
assert x == b'domain-hello', x
print('TCP_OK', host)
'''
router.succeed("cat > /tmp/echodns.py <<'PYEOF'\n" + echodns + "PYEOF\n")

udpecho = '''import socket, sys
host, port = sys.argv[1], int(sys.argv[2])
ai = socket.getaddrinfo(host, port, socket.AF_INET, socket.SOCK_DGRAM)
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.settimeout(10)
s.sendto(b'udp-hello', ai[0][4])
x, _ = s.recvfrom(4096)
assert x == b'udp-hello', x
print('UDP_OK', host)
'''
router.succeed("cat > /tmp/udpecho.py <<'PYEOF'\n" + udpecho + "PYEOF\n")

aaaa = '''import socket, sys
host, port = sys.argv[1], int(sys.argv[2])
ai = socket.getaddrinfo(host, port, socket.AF_INET6, socket.SOCK_STREAM)
addr = ai[0][4][0]
assert ':' in addr, addr
print('AAAA_OK', host, addr)
'''
router.succeed("cat > /tmp/aaaa.py <<'PYEOF'\n" + aaaa + "PYEOF\n")

print("=== root -> echo.example.test TCP (expect TCP_OK) ===")
print(router.succeed("python3 /tmp/echodns.py echo.example.test 9999"))
print("=== root -> echo.example.test UDP (expect UDP_OK) ===")
print(router.succeed("python3 /tmp/udpecho.py echo.example.test 9999"))
print("=== root -> echo.example.test AAAA (expect AAAA_OK) ===")
print(router.succeed("python3 /tmp/aaaa.py echo.example.test 9999"))

print("=== mihomo logs (domain should appear in dial) ===")
print(router.succeed("journalctl -u user-tun-mihomo.service -n 60 --no-pager || true"))