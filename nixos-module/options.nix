{
  lib,
  pkgs,
}:
{
  options.services.user-tun.single-user = {
    enable = lib.mkEnableOption "UserTun single-user TUN proxy (system sing-box tunnels to per-user mihomo)";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.sing-box;
      description = ''
        The `sing-box` package used by the system tun service.
      '';
    };

    socksPort = lib.mkOption {
      type = lib.types.port;
      default = 7890;
      description = ''
        The mixed/socks port of the user's mihomo that sing-box dials
        directly. Keep this in sync with the user-side mihomo config.
      '';
    };

    tunAddress = lib.mkOption {
      type = lib.types.str;
      default = "172.18.0.1/30";
      description = ''
        IPv4 address of the tun interface. Default matches the sing-box
        official example.
      '';
    };

    tunInet6Address = lib.mkOption {
      type = lib.types.str;
      default = "fdfe:dcba:9876::1/126";
      description = ''
        IPv6 address of the tun interface. Default matches the sing-box
        official example.
      '';
    };

    fakeIpRange = lib.mkOption {
      type = lib.types.str;
      default = "198.18.0.0/15";
      description = ''
        IPv4 fake-ip range. Default matches the sing-box official example.
      '';
    };

    fakeIp6Range = lib.mkOption {
      type = lib.types.str;
      default = "2001:2::/48";
      description = ''
        IPv6 fake-ip range. Default matches the sing-box official example.
      '';
    };
  };
}
