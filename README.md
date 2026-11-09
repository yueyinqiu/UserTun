# UserTun

A NixOS module that turns all traffic into a system sing-box tun and forwards it to the user-side proxy.

- **System side**: sing-box opens a single tun (`auto_route`); all traffic (v4/v6) enters the tun, DNS goes through fake-ip, then a socks outbound dials directly to the user-side proxy on the host.
- **User side**: actual proxy nodes and routing rules live in your own proxy; the system side doesn't touch them.

Single-user flavor — no per-uid multi-tun splitting. Suits "one machine, one user, system opens the tun, proxy config belongs to the user".

## Usage

flake:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    user-tun.url = "github:yueyinqiu/UserTun";
  };

  outputs = { nixpkgs, user-tun, ... }: {
    nixosConfigurations.host = nixpkgs.lib.nixosSystem {
      modules = [
        user-tun.nixosModules.default
        {
          services.user-tun.single-user = {
            enable = true;
            # socksPort = 7890;  # default, see below
          };
        }
      ];
    };
  };
}
```

## User side (proxy)

The system side only forwards traffic; the actual proxy config lives in your user-side proxy (mihomo / sing-box / clash, anything that speaks socks). Two conventions:

1. the proxy's `mixed-port` (or socks port) = `services.user-tun.single-user.socksPort` (default `7890`) — sing-box dials that port;
2. set `interface-name` to the real outbound NIC, so the proxy's own egress doesn't get pulled back into sing-box's tun (loop).

Minimal example (in real deployment this lives in your home config):

```yaml
mixed-port: 7890
interface-name: eth0   # your outbound NIC
# ... your proxies / proxy-groups / rules
```

## Options

All options live under `services.user-tun.single-user.`:

| Option | Type | Default | Description |
|---|---|---|---|
| `enable` | bool | `false` | whether to enable |
| `sing-box-package` | package | `pkgs.sing-box` | the sing-box package |
| `socksPort` | port | `7890` | socks port of the user-side proxy |
| `tunAddress` | str | `172.18.0.1/30` | IPv4 address of the tun interface |
| `tunInet6Address` | str | `fdfe:dcba:9876::1/126` | IPv6 address of the tun interface |
| `fakeIpRange` | str | `198.18.0.0/15` | IPv4 fake-ip range |
| `fakeIp6Range` | str | `2001:2::/48` | IPv6 fake-ip range |

## Tests

Tests live in their own flake under `test/`:

```sh
cd test && nix flake check
```

`test/` contains a pair of NixOS VMs (router + target echo server) verifying tun ingress, fake-ip domain handoff to the user-side proxy, and `interface-name` egress, covering TCP / UDP / AAAA.

## License

MIT