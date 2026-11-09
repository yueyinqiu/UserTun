{
  description = "UserTun — per-user TUN proxy via system sing-box (single-user flavor)";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      nixosModules = {
        default = import ./nixos-module;
        user-tun = import ./nixos-module;
      };

      checks.${system}.default = pkgs.testers.runNixOSTest {
        name = "user-tun-domain";
        nodes = {
          router = ./test/router.nix;
          target = ./test/target.nix;
        };

        testScript = builtins.readFile ./test/test-script.py;
      };
    };
}