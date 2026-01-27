{ stdenv, fetchurl }:
stdenv.mkDerivation {
  name = "example";
  src = fetchurl {
    url = "<url>";
    sha256 = "<hash>";
  };

  configurePhase = ''
    ./configure --prefix=$out
  '';

  buildPhase = ''
    make
  '';

  installPhase = ''
    make install
  '';
}
