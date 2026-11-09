{
  description = "UserTun tests";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      checks.${system}.default = pkgs.testers.runNixOSTest {
        name = "user-tun-domain";
        nodes = {
          router = ./router.nix;
          target = ./target.nix;
        };
        testScript = builtins.readFile ./test-script.py;
      };
    };
}