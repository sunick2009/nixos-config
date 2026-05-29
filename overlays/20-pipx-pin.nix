self: super:
let
  version = "1.7.1";
  src = super.fetchPypi {
    pname = "pipx";
    inherit version;
    hash = "sha256-di3hNOFqRivpJkUWbSJezvRGr671NJF/X3AAjWNYQ2A=";
  };
  overridePipx = old: {
    inherit version src;
    doCheck = false;
  };
in {
  pipx = super.pipx.overridePythonAttrs overridePipx;
}
