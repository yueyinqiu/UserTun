{
  config,
  lib,
  pkgs,
}:
let
  cfg = config.services.user-tun.single-user;

  singBoxConfig = pkgs.writeText "user-tun-sing-box.json" (builtins.toJSON {
    log = { level = "info"; };
    dns = {
      servers = [
        { type = "local"; tag = "local"; }
        {
          type = "fakeip";
          tag = "fakeip";
          inet4_range = cfg.fakeIpRange;
          inet6_range = cfg.fakeIp6Range;
        }
      ];
      rules = [
        { server = "fakeip"; }
      ];
      final = "local";
    };
    inbounds = [
      {
        type = "tun";
        tag = "tun";
        stack = "gvisor";
        address = [
          cfg.tunAddress
          cfg.tunInet6Address
        ];
        auto_route = true;
      }
    ];
    outbounds = [
      {
        type = "socks";
        tag = "mihomo";
        server = "127.0.0.1";
        server_port = cfg.socksPort;
        version = "5";
      }
    ];
    route = {
      rules = [
        { port = [ 53 ]; action = "hijack-dns"; }
      ];
      final = "mihomo";
    };
  });
in
{
  systemd.services.user-tun-singbox = {
    description = "UserTun system sing-box (tun -> per-user mihomo)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      DynamicUser = true;
      ExecStart = "${lib.getExe cfg.package} run -c ${singBoxConfig}";
      Restart = "on-failure";
      AmbientCapabilities = [ "CAP_NET_ADMIN" ];
      PrivateDevices = false;
      PrivateUsers = false;
    };
  };
}