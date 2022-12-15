{ pkgs }:
import ./pythonless-wrapper.nix {
  inherit pkgs;
  pkg = pkgs.python3.withPackages (ps: [ ps.tox ] );
  scripts = [ "tox" ];
}
