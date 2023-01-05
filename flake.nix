{
  description = "GridSync, Tahoe-LAFS/magic-folder GUI";
  inputs.nixpkgs = {
    url = "github:NixOS/nixpkgs?ref=nixos-22.05";
  };
  inputs.flake-utils = {
    url = "github:numtide/flake-utils";
  };
  inputs.pypi-deps-db = {
    flake = false;
    url = "github:DavHau/pypi-deps-db";
  };
  inputs.mach-nix = {
    flake = true;
    url = "github:DavHau/mach-nix";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
      pypi-deps-db.follows = "pypi-deps-db";
    };
  };
  outputs = { self, nixpkgs, flake-utils, mach-nix, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system: let

      # The version of Python we'll use to set up the environment.
      pythonVersion = "python3.9";

      # Many Nix-related tools don't want the `.` in the Python derivation
      # identifier.  Generate a string in the right format for them.
      python = builtins.replaceStrings ["."] [""] pythonVersion;

      pkgs = nixpkgs.legacyPackages.${system};

      pyqtchart = { callPackage, libsForQt5 }:
        with libsForQt5;
        callPackage ./pyqtchart.nix {
          pyqtchart-qt = callPackage ./pyqtchart-qt.nix { inherit (qt5) full; };
          inherit qmake;
          inherit (qt5) qtbase;
          inherit qtcharts;
        };

      gridsync-env =
        # we need a Python to run gridsync, so it needs those dependencies
        # we find those by reading its packaging source code
        (pkgs.${python}.withPackages (ps: with ps; [
          # tahoe-capabilities
          atomicwrites
          attrs
          autobahn
          certifi
          distro
          filelock
          humanize
          hyperlink
          magic-wormhole
          psutil
          pynacl
          (callPackage pyqtchart {})
          pyqt5
          pyyaml
          qtpy
          treq
          twisted
          txdbus
          txtorcon
          watchdog
          zxcvbn
          (callPackage tahoe-capabilities {}) # callPackage is just MAGIC!
        ]));

      tox-env = pkgs.${python}.withPackages (ps: [ ps.tox ] );
      tox-derivation = pkgs.writeScript "./bin/tox.sh" ''
          ${tox-env}/bin/python -m tox "$@"
          '';

      tahoe-env = mach-nix.lib.${system}.mkPython {
        inherit python;
        # mach-nix can't parse the .txt files so we can't easily match the
        # exact dependency versions the pip-based toolchain will use.  We can
        # get close, though.
        requirements = builtins.readFile ./requirements/tahoe-lafs.in;
      };

      tahoe-capabilities = { lib, buildPythonPackage, fetchPypi, attrs }:
        buildPythonPackage rec {
          pname = "tahoe-capabilities";
          version = "2023.1.5";
          buildInputs = [ attrs ];

          src = fetchPypi {
            inherit pname version;
            sha256 = "sha256-PdHCrznvsiOmdySrJOXB9GcDXfxqJPOUG0rL/8S/3D8=";
          };

          doCheck = false;

          meta = with lib; {
            homepage = "https://github.com/tahoe-lafs/tahoe-capabilities";
            description = "Simple, re-usable types for interacting with Tahoe-LAFS capabilities";
            license = licenses.gpl2;
            maintainers = with maintainers; [ exarkun ];
          };
        };

      magic-folder-env = mach-nix.lib.${system}.mkPython {
        inherit python;
        # See comment on tahoe-env definition.
        requirements = builtins.readFile ./requirements/magic-folder.in;
      };

      # Build an FHS user environment that contains Qt native library
      # dependencies and some Python tools.  This is suitable for running tox
      # in.  `runScript` is the command to run in the FHS env's chroot.
      makeDevShell = runScript: pkgs.buildFHSUserEnv {
        name = "dev-env";
        profile = (
          # Usually bytecode is just a nuisance - getting stale, taking more
          # time to read/write than it saves, or creating extra noise in the
          # checkout with generated files.
          ''
          export PYTHONDONTWRITEBYTECODE=1
          ''

          # If there are any Qt plugins installed on the host system then we
          # must not let information about them leak into the dev environment.
          # The PyQt/Qt libraries we use for GridSync are almost certainly not
          # compatible with whatever is on the system and if the two get too
          # close to each other, Qt tends to SIGABRT itself.
          #
          # Clear this plugin path environment variable so any host plugin
          # libraries aren't discovered.
          + ''
          unset QT_PLUGIN_PATH
          ''

          # tox has its own ideas about what the default Python should be,
          # without regard to what version of Python is actually available on
          # the system.  Convince it to agree with the environment we've set
          # up.
          + ''
          export TOX_BASEPYTHON=${pythonVersion}
          ''

          # Sometimes the information Qt dumps when this variable is set is
          # useful for debugging Qt-related problems (especially problems
          # finding or loading certain Qt plugins).  It's pretty noisy so it's
          # not on by default.
          + ''
          # export QT_DEBUG_PLUGINS=1
          ''
        );

        # Install some libraries in the environment (only versions for the
        # target architecture).
        targetPkgs = pkgs: (with pkgs;
          [
            # GridSync depends on PyQt5.  The PyQt5 wheel bundles Qt5 itself
            # but not the dependencies of those libraries.  Supply them.
            dbus.lib
            fontconfig
            freetype
            glib
            libGL
            libstdcxx5
            libxkbcommon
            qt5.full
            xorg.libX11
            xorg.libXext
            xorg.libxcb
            xorg.xcbutil
            xorg.xcbutilimage
            xorg.xcbutilkeysyms
            xorg.xcbutilrenderutil
            xorg.xcbutilwm
            zlib

            # after this point, manually add lots of necessary things
            gridsync-env

            # Put tox into the environment for "easy" testing
            (import ./tox.nix { inherit pkgs; })

            (import ./pythonless-wrapper.nix {
              inherit pkgs;
              pkg = (pkgs.python3.withPackages (ps: [ ps.mypy ]));
              scripts = [ "mypy" ];
            })

            # GridSync also depends on `tahoe` and `magic-folder` CLI tools.
            (import ./pythonless-wrapper.nix {
              inherit pkgs;
              pkg = tahoe-env;
              scripts = [ "tahoe" ];
            })

            (import ./pythonless-wrapper.nix {
              inherit pkgs;
              pkg = magic-folder-env;
              scripts = [ "magic-folder" ];
            })
          ]);
        inherit runScript;
      };

    in {
      devShells = {
        # The default is to run an interactive shell.
        default = (makeDevShell "bash").env;
      };

      apps.tox =
        let
          xvfb-tox = pkgs.writeScript "xvfb-tox" ''
            ${pkgs.xvfb-run}/bin/xvfb-run --auto-servernum tox "$@"
          '';
        in {
          type = "app";
          # Run the env-entering script from the FHS user environment.
          # Arguments from the command line will be passed along.
          # pkgs/build-support/build-fhs-userenv/default.nix for gory details.
          program = "${makeDevShell xvfb-tox}/bin/dev-env";
        };
      apps.gridsync =
        let
          gridsync = pkgs.writeScript "gridsync" ''
          python -m gridsync.cli "$@"
          '';
        in {
          type = "app";
          # Run the env-entering script from the FHS user environment.
          # Arguments from the command line will be passed along.
          # pkgs/build-support/build-fhs-userenv/default.nix for gory details.
          program = "${makeDevShell gridsync}/bin/dev-env"; # where do we get dev-env? nobody knows
        };
    });
}
