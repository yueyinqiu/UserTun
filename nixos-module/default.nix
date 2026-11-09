{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (import ./options.nix {
      lib = lib;
      pkgs = pkgs;
    })
  ];

  config = lib.mkIf config.services.user-tun.single-user.enable (
    import ./config.nix {
      config = config;
      lib = lib;
      pkgs = pkgs;
    }
  );
}
