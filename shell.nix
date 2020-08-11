{ default ? import ./default.nix {} }:

let
  inherit (default) project pkgs;

  pkgs-unstable = import sources."nixpkgs" {};
  inherit (pkgs-unstable) cabal-install;

  local =
    if builtins.pathExists ./shell.local.nix
    then import ./shell.local.nix { inherit default; }
    else x: x;
  shellFor = args: project.shellFor (local args);

  sources = import ./nix/sources.nix;

  ghcide-project = default.pkgs.haskell-nix.project {
    src = sources."ghcide";
    projectFileName = "stack810.yaml";
    modules = [
      # This fixes a performance issue, probably https://gitlab.haskell.org/ghc/ghc/issues/15524
      { packages.ghcide.configureFlags = [ "--enable-executable-dynamic" ]; }
    ];
  };
  inherit (ghcide-project.ghcide.components.exes) ghcide;
  inherit (ghcide-project.hie-bios.components.exes) hie-bios;

  hlint-project = default.pkgs.haskell-nix.stackProject {
    src = sources."hlint";
  };
  inherit (hlint-project.hlint.components.exes) hlint;
in

shellFor {
  buildInputs = with pkgs; [
    cabal-install ghcid hlint
    ghcide hie-bios
  ];
}
