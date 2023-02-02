# copied from https://github.com/prehonor/nixos/blob/master/nixpkgs-overlays/pkgs/development/python-modules/
# credit to prehonor

{ lib
, buildPythonPackage
}:


buildPythonPackage rec {
  pname = "gridsync";
  version = "0.6.1";
  src = ./.;
  format = "setuptools";

  # Checked using pythonImportsCheck
  doCheck = false;

  meta = with lib; {
    description = "GridSync is totally awesome and if you're not using it, you're missing out.";
    license = licenses.gpl3;
    maintainers = [ "Private Storage" ] ;
    homepage = "https://private.storage";
  };
}
