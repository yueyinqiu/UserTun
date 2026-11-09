{
  description = "UserTun — per-user TUN proxy via system sing-box (single-user flavor)";

  outputs = { self }:
    {
      nixosModules = {
        default = import ./nixos-module;
        user-tun = import ./nixos-module;
      };
    };
}