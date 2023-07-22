{ lib
, stdenvNoCC
, rustPlatform
, fetchFromGitHub
, buildNpmPackage
, makeWrapper
, perl
, pkg-config
, glib
, webkitgtk
, libappindicator-gtk3
, libayatana-appindicator
, cairo
, openssl
}:

let
  version = "4.8.9";
  geph-meta = with lib; {
    description = "A modular Internet censorship circumvention system designed specifically to deal with national filtering.";
    homepage = "https://geph.io";
    platforms = platforms.linux;
    maintainers = with maintainers; [ penalty1083 ];
  };
in
rec {
  cli = rustPlatform.buildRustPackage rec {
    pname = "geph4-client";
    inherit version;

    src = fetchFromGitHub {
      owner = "geph-official";
      repo = pname;
      rev = "v${version}";
      hash = "sha256-suV2HB2YwbHatluklAHFNLauD8yz4eNQ0er2M9VP7tM=";
    };

    cargoHash = "sha256-Lx1VKIoWsiq7yju5zH6wny/n/qFWC3MFgqrEt1xtwqA=";

    nativeBuildInputs = [ perl ];

    meta = geph-meta // {
      license = with lib.licenses; [ gpl3Only ];
    };
  };

  gui = stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "geph-gui";
    inherit version;

    src = fetchFromGitHub {
      owner = "geph-official";
      repo = "gephgui-pkg";
      rev = "1974ce95b908cb16dafa7c19f732ae27ff2928a8";
      hash = "sha256-4BVplOEBm4kGhG8Dc4uBv76s2Y3wDxHsZQdpvro9hUY=";
      fetchSubmodules = true;
    };

    gephgui = buildNpmPackage {
      pname = "gephgui";
      inherit (finalAttrs) version src;

      sourceRoot = "source/gephgui-wry/gephgui";

      postPatch = "ln -s ${./package-lock.json} ./package-lock.json";

      npmDepsHash = "sha256-U0fiS0aGOulPE4cQ/nTL3UQGKnvHKlzt+y365DNiyY8=";

      installPhase = ''
        runHook preInstall

        mkdir -p $out
        mv dist $out

        runHook postInstall
      '';
    };

    gephgui-wry = rustPlatform.buildRustPackage {
      pname = "gephgui-wry";
      inherit (finalAttrs) version src;

      sourceRoot = "source/gephgui-wry";

      cargoLock = {
        lockFile = ./Cargo.gui.lock;
        outputHashes = {
          "tao-0.5.2" = "sha256-HyQyPRoAHUcgtYgaAW7uqrwEMQ45V+xVSxmlAZJfhv0=";
          "wry-0.12.2" = "sha256-kTMXvignEF3FlzL0iSlF6zn1YTOCpyRUDN8EHpUS+yI=";
        };
      };

      nativeBuildInputs = [ pkg-config ];

      buildInputs = [
        glib
        webkitgtk
        libappindicator-gtk3
        libayatana-appindicator
        cairo
        openssl
      ];

      preBuild = ''
        ln -s ${finalAttrs.gephgui}/dist ./gephgui
      '';
    };

    nativeBuildInputs = [ makeWrapper ];

    dontBuild = true;

    installPhase = ''
      runHook preInstall

      install -Dt $out/bin ${finalAttrs.gephgui-wry}/bin/gephgui-wry
      wrapProgram $out/bin/gephgui-wry --suffix PATH : ${lib.makeBinPath [ cli ]}
      install -d $out/share/icons/hicolor
      for i in '16' '32' '64' '128' '256'
      do
        name=''${i}x''${i}
        dir=$out/share/icons/hicolor
        mkdir -p $dir
        mv flatpak/icons/$name $dir
      done
      install -Dt $out/share/applications flatpak/icons/io.geph.GephGui.desktop
      sed -i -e '/StartupWMClass/s/=.*/=gephgui-wry/' $out/share/applications/io.geph.GephGui.desktop

      runHook postInstall
    '';

    meta = geph-meta // {
      license = with lib.licenses; [ unfree ];
    };
  });
}
