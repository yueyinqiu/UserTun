{
  config,
  lib,
  pkgs,
}:
let
  cfg = config.services.user-tun.single-user;

  singBoxConfig = pkgs.writeText "user-tun-sing-box.json" (
    builtins.toJSON {
      log = {
        level = "info";
      };
      dns = {
        servers = [
          {
            type = "local";
            tag = "local";
          }
          {
            type = "fakeip";
            tag = "fakeip";
            inet4_range = cfg.fakeIp4Range;
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
            cfg.tun4Address
            cfg.tun6Address
          ];
          auto_route = true;
        }
      ];
      outbounds = [
        {
          type = "socks";
          tag = "user-tun";
          server = "127.0.0.1";
          server_port = cfg.upstreamPort;
          version = "5";
        }
      ];
      route = {
        rules = [
          {
            port = [ 53 ];
            action = "hijack-dns";
          }
        ];
        final = "user-tun";
      };
    }
  );
in
{
  systemd.services.user-tun-singbox = {
    description = "UserTun system sing-box (tun -> user-side proxy)";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      DynamicUser = true;
      ExecStart = "${lib.getExe cfg.sing-box-package} run -c ${singBoxConfig}";
      Restart = "on-failure";
      AmbientCapabilities = [ "CAP_NET_ADMIN" ];
      PrivateDevices = false;
      PrivateUsers = false;
    };
  };
}
