{ lib
, stdenv
, fetchFromGitHub
, rust
, rustPlatform
, cmake
, just
, pkg-config
, makeBinaryWrapper
, libxkbcommon
, linux-pam
, wayland
, coreutils
, cosmic-settings
, cosmic-icons
}:

rustPlatform.buildRustPackage {
  pname = "cosmic-greeter";
  version = "0-unstable-2024-02-25";

  src = fetchFromGitHub {
    owner = "pop-os";
    repo = "cosmic-greeter";
    rev = "df9f2092e80f04afeabe68cde92732e450c17683";
    sha256 = "sha256-pMtpnTJzml5s/8uf7cW4njhilNJXs24QGWi/ILsBGNA=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "accesskit-0.11.0" = "sha256-xVhe6adUb8VmwIKKjHxwCwOo5Y1p3Or3ylcJJdLDrrE=";
      "atomicwrites-0.4.2" = "sha256-QZSuGPrJXh+svMeFWqAXoqZQxLq/WfIiamqvjJNVhxA=";
      "cosmic-bg-config-0.1.0" = "sha256-fdRFndhwISmbTqmXfekFqh+Wrtdjg3vSZut4IAQUBbA=";
      "cosmic-client-toolkit-0.1.0" = "sha256-vj7Wm1uJ5ULvGNEwKznNhujCZQiuntsWMyKQbIVaO/Q=";
      "cosmic-config-0.1.0" = "sha256-NRqpgQjLf6ZijhcnyWdVsCam4W/gtVf/b2+m+7IzW4o=";
      "cosmic-dbus-networkmanager-0.1.0" = "sha256-z/dvRyc3Zc1fAQh2HKk6NI6QSDpNqarqslwszjU+0nc=";
      "cosmic-text-0.10.0" = "sha256-WxT0LPXu17jb0XpuCu2PjlGTV1a0K1HMhl6WpciKMkM=";
      "glyphon-0.4.1" = "sha256-mwJXi63LTBIVFrFcywr/NeOJKfMjQaQkNl3CSdEgrZc=";
      "smithay-client-toolkit-0.18.0" = "sha256-2WbDKlSGiyVmi7blNBr2Aih9FfF2dq/bny57hoA4BrE=";
      "softbuffer-0.3.3" = "sha256-eKYFVr6C1+X6ulidHIu9SP591rJxStxwL9uMiqnXx4k=";
      "taffy-0.3.11" = "sha256-SCx9GEIJjWdoNVyq+RZAGn0N71qraKZxf9ZWhvyzLaI=";
    };
  };

  nativeBuildInputs = [ rustPlatform.bindgenHook cmake just pkg-config makeBinaryWrapper ];
  buildInputs = [ libxkbcommon wayland linux-pam ];

  cargoBuildFlags = [ "--all" ];

  dontUseJustBuild = true;

  justFlags = [
    "--set"
    "prefix"
    (placeholder "out")
    "--set"
    "bin-src"
    "target/${rust.lib.toRustTargetSpecShort stdenv.hostPlatform}/release/cosmic-greeter"
    "--set"
    "daemon-src"
    "target/${rust.lib.toRustTargetSpecShort stdenv.hostPlatform}/release/cosmic-greeter-daemon"
  ];

  postPatch = ''
    substituteInPlace src/greeter.rs --replace '/usr/bin/env' '${lib.getExe' coreutils "env"}'
  '';

  postInstall = ''
    wrapProgram $out/bin/cosmic-greeter \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ wayland ]}" \
      --suffix XDG_DATA_DIRS : ${cosmic-settings}/share:${cosmic-icons}/share

    wrapProgram $out/bin/cosmic-greeter-daemon \
      --suffix XDG_DATA_DIRS : ${cosmic-settings}/share:${cosmic-icons}/share
  '';

  meta = with lib; {
    homepage = "https://github.com/pop-os/cosmic-greeter";
    description = "Greeter for the COSMIC Desktop Environment";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ nyanbinary ];
    platforms = platforms.linux;
  };
}
