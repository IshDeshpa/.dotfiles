self: super:

{
  fuzzmoji = super.stdenv.mkDerivation rec {
    pname = "fuzzmoji";
    version = "1.0.0";

    # Use fetchzip to fetch the zip archive
    src = super.fetchzip {
      url = "https://codeberg.org/codingotaku/fuzzmoji/archive/refs/heads/main.zip";  # URL to the zip file
      sha256 = "sha256-19h0vqc8bvdq5xbcdh3w5h7nzq07gw0216cmhx381d0zb03r64dm";  # The correct hash
    };

    nativeBuildInputs = [ super.makeWrapper ];

    installPhase = ''
      mkdir -p $out/usr/share/fuzzmoji
      cp $src/fuzzmoji-main/emoji-list $out/usr/share/fuzzmoji/emoji-list
      cp $src/fuzzmoji-main/fuzzmoji $out/usr/bin/fuzzmoji
    '';

    meta = {
      license = super.lib.licenses.mit;
      platforms = super.lib.platforms.linux;
    };
  };
}

