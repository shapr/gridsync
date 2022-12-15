# A function that returns a derivation that gives access to the named scripts
# from another derivation but does not propagate that derivation's propagated
# inputs, nor does it add any other scripts from that derivation's bin
# directory to PATH.
{ pkgs # :: nixpkgs
, pkg # :: derivation
, scripts # :: [string]
}: # -> derivation
let
  inherit (pkgs) bash coreutils;

  # Return a string containing a bash program that writes a program with the
  # given name to the output bin directory.  The bash program will run the
  # named Python mainpoint.
  generateScript = name: ''
      echo '#!${bash}/bin/bash
            ${pkg}/bin/${name} "$@" ' > $out/bin/${name}
  '';
in
# define a set of operations to take to create a store object
derivation rec {
  name = builtins.head scripts;

  builder = "${bash}/bin/bash";
  args = [
    "-c"
    ''
    set -euo pipefail

    ${coreutils}/bin/mkdir -p $out/bin
    ${generateScript (builtins.head scripts)}
    ${coreutils}/bin/chmod +x $out/bin/*
    ''
  ];
  # system = builtins.currentSystem; THIS DOES NOT WORK
  system = pkgs.system;
}
