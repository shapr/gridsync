# copied from https://github.com/prehonor/nixos/blob/master/nixpkgs-overlays/pkgs/development/python-modules/
# credit to prehonor

{ gridsync-packages
, lib
, buildPythonPackage
, python
, wrapQtAppsHook
}:


buildPythonPackage rec {
  pname = "gridsync";
  version = "0.6.1";
  src = ./.;
  format = "setuptools";
  buildInputs = [wrapQtAppsHook ];
  propagatedBuildInputs = gridsync-packages python.pkgs;

  # Checked using pythonImportsCheck
  doCheck = false;

  meta = with lib; {
    description = "GridSync is totally awesome and if you're not using it, you're missing out.";
    license = licenses.gpl3;
    maintainers = [ "Private Storage" ] ;
    homepage = "https://private.storage";
  };
}
