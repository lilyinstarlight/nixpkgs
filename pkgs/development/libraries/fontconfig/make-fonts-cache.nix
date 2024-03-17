{ runCommand, lib, fontconfig, fontconfigEtc ? fontconfig.out, fontDirectories }:

runCommand "fc-cache"
  {
    nativeBuildInputs = [ fontconfig.bin ];
    preferLocalBuild = true;
    allowSubstitutes = false;
    passAsFile = [ "fontDirs" ];
    fontDirs = ''
      <!-- Font directories -->
      ${lib.concatStringsSep "\n" (map (font: "<dir>${font}</dir>") fontDirectories)}
    '';
  }
  ''
    export FONTCONFIG_FILE=$(pwd)/fc-cache.conf
    export FONTCONFIG_PATH=${fontconfigEtc}/etc/fonts

    cat > fc-cache.conf << EOF
    <?xml version='1.0'?>
    <!DOCTYPE fontconfig SYSTEM 'urn:fontconfig:fonts.dtd'>
    <fontconfig>
      <include>fonts.conf</include>
      <cachedir>$out</cachedir>
    EOF
    cat "$fontDirsPath" >> fc-cache.conf
    echo "</fontconfig>" >> fc-cache.conf

    mkdir -p $out
    fc-cache -sv

    # This is not a cache dir in the normal sense -- it won't be automatically
    # recreated.
    rm -f "$out/CACHEDIR.TAG"
  ''
