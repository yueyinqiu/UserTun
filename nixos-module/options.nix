{
  lib,
  pkgs,
}:
{
  options.services.user-tun.single-user = {
    enable = lib.mkEnableOption "UserTun single-user TUN proxy (system sing-box tunnels to the user-side proxy)";

    sing-box-package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.sing-box;
      description = ''
        The `sing-box` package used by the system tun service.
      '';
    };

    upstreamPort = lib.mkOption {
      type = lib.types.port;
      default = 7890;
      description = "The socks port of the user-side proxy (sing-box's upstream) that sing-box dials directly.";
    };

    tun4Address = lib.mkOption {
      type = lib.types.str;
      default = "172.18.0.1/30";
      description = "IPv4 address of the tun interface.";
    };

    tun6Address = lib.mkOption {
      type = lib.types.str;
      default = "fdfe:dcba:9876::1/126";
      description = "IPv6 address of the tun interface.";
    };

    fakeIp4Range = lib.mkOption {
      type = lib.types.str;
      default = "198.18.0.0/15";
      description = "IPv4 fake-ip range.";
    };

    fakeIp6Range = lib.mkOption {
      type = lib.types.str;
      default = "2001:2::/48";
      description = "IPv6 fake-ip range.";
    };
  };
}
