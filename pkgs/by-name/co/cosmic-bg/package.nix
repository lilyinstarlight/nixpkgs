{ lib
, stdenv
, fetchFromGitHub
, rustPlatform
, just
, nasm
, pkg-config
, makeBinaryWrapper
, libxkbcommon
, wayland
}:

rustPlatform.buildRustPackage {
  pname = "cosmic-bg";
  version = "0-unstable-2024-02-01";

  src = fetchFromGitHub {
    owner = "pop-os";
    repo = "cosmic-bg";
    rev = "a1f0552187a9e9c436b392908b76866dea482345";
    hash = "sha256-2P2NcgDmytvBCMbG8isfZrX+JirMwAz8qjW3BhfhebI=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "atomicwrites-0.4.2" = "sha256-QZSuGPrJXh+svMeFWqAXoqZQxLq/WfIiamqvjJNVhxA=";
      "cosmic-config-0.1.0" = "sha256-UTxeUjyiTZ8aE75ccHbSNj+ZhF5ncx0LUv3nlsqj6x0=";
      "smithay-client-toolkit-0.18.0" = "sha256-7s5XPmIflUw2qrKRAZUz30cybYKvzD5Hu4ViDpzGC3s=";
    };
  };

  postPatch = ''
    substituteInPlace justfile --replace '#!/usr/bin/env' "#!$(command -v env)"
  '';

  nativeBuildInputs = [ just nasm pkg-config makeBinaryWrapper ];
  buildInputs = [ libxkbcommon wayland ];

  dontUseJustBuild = true;

  justFlags = [
    "--set"
    "prefix"
    (placeholder "out")
    "--set"
    "bin-src"
    "target/${stdenv.hostPlatform.rust.cargoShortTarget}/release/cosmic-bg"
  ];

  postInstall = ''
    wrapProgram $out/bin/cosmic-bg \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [wayland]}"
  '';

  meta = with lib; {
    homepage = "https://github.com/pop-os/cosmic-bg";
    description = "Applies Background for the COSMIC Desktop Environment";
    license = licenses.mpl20;
    maintainers = with maintainers; [ nyanbinary ];
    platforms = platforms.linux;
    mainProgram = "cosmic-bg";
  };
}
