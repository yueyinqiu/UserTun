# UserTun

系统级 sing-box 单 tun 转发到用户侧代理的 NixOS module。

- **系统侧**：sing-box 开一个 tun（`auto_route`），所有流量（v4/v6）都进 tun，DNS 走 fake-ip，然后经一个 socks outbound 直连到本机的用户侧代理。
- **用户侧**：具体代理节点、分流规则都在用户自己的代理里，系统侧不碰这些。

单用户版，不做按 uid 分流的复杂多 tun；适合「一台机器一个用户、系统统一开 tun、代理配置归用户自己」的场景。

## 用法

flake：

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
            # socksPort = 7890;  # 默认，见下方「用户侧」
          };
        }
      ];
    };
  };
}
```

## 用户侧（proxy）

系统侧只负责把流量转发过来，真正的代理配置在你的用户侧代理里（mihomo / sing-box / clash 都行，只要是个 socks 服务）。约定两点：

1. 代理的 `mixed-port`（或 socks 端口）= `services.user-tun.single-user.socksPort`（默认 `7890`），sing-box 直连这个端口；
2. 代理配置 `interface-name` 指向真实出站网卡，避免代理自己的出站被 sing-box 的 tun 拽回去（回环）。

最小示例（真实里放在 home config）：

```yaml
mixed-port: 7890
interface-name: eth0   # 你的出站网卡名
# ... 你的 proxies / proxy-groups / rules
```

## Options

以下 option 都在 `services.user-tun.single-user.` 命名空间下：

| Option | 类型 | 默认 | 说明 |
|---|---|---|---|
| `enable` | bool | `false` | 启用 |
| `sing-box-package` | package | `pkgs.sing-box` | sing-box 包 |
| `socksPort` | port | `7890` | 用户侧代理的 socks 端口 | |
| `tunAddress` | str | `172.18.0.1/30` | tun IPv4 地址 |
| `tunInet6Address` | str | `fdfe:dcba:9876::1/126` | tun IPv6 地址 |
| `fakeIpRange` | str | `198.18.0.0/15` | fake-ip IPv4 段 |
| `fakeIp6Range` | str | `2001:2::/48` | fake-ip IPv6 段 |

后四个默认值都照抄 sing-box 官方示例。

## 测试

```sh
nix flake check
```

`test/` 里是一对 NixOS 虚拟机（router + target echo server），验证 tun 进流量、fake-ip 域名下发到用户侧代理、`interface-name` 出站，覆盖 TCP / UDP / AAAA。

## License

MIT