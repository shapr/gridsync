{pkgs }:
# define a set of operations to take to create a store object
let
  tox-env = pkgs.python3.withPackages (ps: [ ps.tox ] );
in
with pkgs; derivation rec {

  name = "tox.sh";
  builder = "${bash}/bin/bash";
  args = [
    "-c"
    ''
    ${coreutils}/bin/mkdir -p $out/bin &&
    echo '#!${bash}/bin/bash
          ${tox-env}/bin/python -m tox "$@" ' > $out/bin/${name} &&
    ${coreutils}/bin/chmod +x $out/bin/${name}
    ''
  ];
  # system = builtins.currentSystem; THIS DOES NOT WORK
  system = pkgs.system;
}
