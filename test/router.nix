{ config, lib, pkgs, ... }:

let
  yaml = pkgs.formats.yaml { };

  mihomoConfig = yaml.generate "mihomo-config.yaml" {
    mode = "rule";
    log-level = "info";
    ipv6 = true;
    mixed-port = 7890;
    allow-lan = false;
    interface-name = "eth1";
    dns = {
      enable = true;
      hosts = { "echo.example.test" = "192.168.50.2"; };
      nameserver = [ "192.168.50.2" ];
    };
    rules = [
      "DOMAIN,echo.example.test,DIRECT"
      "MATCH,REJECT"
    ];
  };
in
{
  imports = [ ../nixos-module ];

  virtualisation.vlans = [ 1 ];

  networking.interfaces.eth1.ipv4.addresses = [
    { address = "192.168.50.1"; prefixLength = 24; }
  ];

  networking.nameservers = [ "1.1.1.1" ];

  environment.systemPackages = [ pkgs.python3 pkgs.iproute2 ];

  users.users.alice = { isNormalUser = true; uid = 1001; description = "test user"; };

  services.user-tun.single-user = {
    enable = true;
  };

  systemd.services.user-tun-mihomo = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      User = "alice";
      StateDirectory = "user-tun-mihomo";
      ExecStart = "${lib.getExe pkgs.mihomo} -d /var/lib/user-tun-mihomo -f ${mihomoConfig}";
      Restart = "on-failure";
    };
  };
}