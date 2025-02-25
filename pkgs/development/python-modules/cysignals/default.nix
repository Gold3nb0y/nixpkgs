{
  lib,
  fetchPypi,
  buildPythonPackage,
  meson-python,
  cython,
  pariSupport ? true,
  pari, # for interfacing with the PARI/GP signal handler

  # Reverse dependency
  sage,
}:

assert pariSupport -> pari != null;

buildPythonPackage rec {
  pname = "cysignals";
  version = "1.12.3";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-ifdibb8p21qz1u/xWomXj061GTwyDpCZvMFX2s3v0es=";
  };

  build-system = [
    cython
    meson-python
  ];

  # explicit check:
  # build/src/cysignals/implementation.c:27:2: error: #error "cysignals must be compiled without _FORTIFY_SOURCE"
  hardeningDisable = [ "fortify" ];

  # known failure: https://github.com/sagemath/cysignals/blob/582dbf6a7b0f9ade0abe7a7b8720b7fb32435c3c/testgdb.py#L5
  doCheck = false;
  checkTarget = "check-install";

  preCheck = ''
    # Make sure cysignals-CSI is in PATH
    export PATH="$out/bin:$PATH"
  '';

  propagatedBuildInputs =
    [ cython ]
    ++ lib.optionals pariSupport [
      # When cysignals is built with pari, including cysignals into the
      # buildInputs of another python package will cause cython to link against
      # pari.
      pari
    ];

  enableParallelBuilding = true;

  passthru.tests = {
    inherit sage;
  };

  meta = with lib; {
    description = "Interrupt and signal handling for Cython";
    mainProgram = "cysignals-CSI";
    homepage = "https://github.com/sagemath/cysignals/";
    maintainers = teams.sage.members;
    license = licenses.lgpl3Plus;
  };
}
