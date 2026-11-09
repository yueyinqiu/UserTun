# UserTun

A NixOS module that turns all traffic into a system sing-box tun and forwards it to a user-side proxy (e.g. mihomo).

## Why

- A proxy is often **personal and private** (your own nodes, credentials, routing rules), while the NixOS config may be shared and admin-maintained — private proxy details don't belong there.
- Opening a tun needs **root** (`CAP_NET_ADMIN`) to create the device and set `auto_route`, but the actual proxy can happily run as a normal user.

So the system side keeps a thin sing-box that only opens a tun and tunnels everything to a local socks port; *which* proxy listens on that port stays in the user's control.

> **Caveat:** this is the **single-user** flavor — sing-box's `auto_route` pulls in all traffic **regardless of uid**. On a machine with multiple users, everyone's traffic would go through the same user-side proxy. Suited for "one machine, one user".

## How it works

```
 all traffic (v4/v6)
   │  auto_route → tun (172.18.0.1/30, fdfe:dcba:9876::1/126)
   ▼
 sing-box (system, root)
   │  DNS → fake-ip, then a socks outbound dials locally
   ▼
 user-side proxy (127.0.0.1:7890) ──► real outbound NIC (interface-name)
```

- sing-box opens one tun with `auto_route = true` and one socks outbound to `127.0.0.1:<socksPort>`;
- DNS is hijacked to fake-ip (v4/v6), so the **domain** is handed off to the proxy instead of a resolved IP — the proxy's own `DOMAIN` rules keep working;
- the proxy sets `interface-name` to the outbound NIC, so its own egress isn't pulled back into the tun (loop).

## Adding as a flake input

```nix
{
  inputs = {
    user-tun.url = "github:yueyinqiu/UserTun";
  };
}
```

## Installation

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    user-tun.url = "github:yueyinqiu/UserTun";
  };

  outputs = { nixpkgs, user-tun, ... }: {
    nixosConfigurations.host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
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

### Module options

Options under `services.user-tun.single-user`:

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `enable` | bool | `false` | Whether to enable UserTun |
| `sing-box-package` | package | `pkgs.sing-box` | The `sing-box` package used by the tun service |
| `socksPort` | port | `7890` | Socks port of the user-side proxy that sing-box dials |
| `tunAddress` | str | `172.18.0.1/30` | IPv4 address of the tun interface |
| `tunInet6Address` | str | `fdfe:dcba:9876::1/126` | IPv6 address of the tun interface |
| `fakeIpRange` | str | `198.18.0.0/15` | IPv4 fake-ip range |
| `fakeIp6Range` | str | `2001:2::/48` | IPv6 fake-ip range |

## User side (proxy)

The system side only forwards traffic; the actual proxy config lives in your user-side proxy (mihomo / sing-box / clash, anything that speaks socks). Two conventions:

1. the proxy's `mixed-port` (or socks port) = `services.user-tun.single-user.socksPort` (default `7890`) — sing-box dials that port;
2. set `interface-name` to the real outbound NIC, so the proxy's own egress doesn't loop back into the tun.

Minimal example (in real deployment this lives in your home config):

```yaml
mixed-port: 7890
interface-name: eth0   # your outbound NIC
# ... your proxies / proxy-groups / rules
```

## Security notes

- sing-box runs as a dynamic unprivileged user (`DynamicUser = true`) with only `CAP_NET_ADMIN` — enough to create the tun and set routes, not root.
- `PrivateUsers = false` keeps that capability in the init user namespace where it can actually touch host networking (a private user namespace would trap it).
- The socks outbound dials `127.0.0.1`, so the proxy stays local.

## Tests

Tests live in their own flake under `test/`:

```sh
cd test && nix flake check
```

`test/` contains a pair of NixOS VMs (router + target echo server) verifying tun ingress, fake-ip domain handoff to the user-side proxy, and `interface-name` egress, covering TCP / UDP / AAAA.

## License

[MIT](LICENSE)

---

All documentation, option `description` fields, and tests in this repository are AI-generated.