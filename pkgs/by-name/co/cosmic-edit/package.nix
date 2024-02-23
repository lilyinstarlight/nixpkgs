{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  cmake,
  makeBinaryWrapper,
  cosmic-icons,
  glib,
  gtk3,
  just,
  pkg-config,
  libglvnd,
  libxkbcommon,
  libinput,
  fontconfig,
  freetype,
  mesa,
  wayland,
  xorg,
  vulkan-loader,
}:

rustPlatform.buildRustPackage {
  pname = "cosmic-edit";
  version = "0-unstable-2024-02-26";

  src = fetchFromGitHub {
    owner = "pop-os";
    repo = "cosmic-edit";
    rev = "944c75ca8a78f1f4ecbc3e4f1a8c68f28c168dce";
    hash = "sha256-i7x9Qis9SqbED4PUJQrdmElplYVaAQ5h5veVR5yB5Rk=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "accesskit-0.12.2" = "sha256-ksaYMGT/oug7isQY8/1WD97XDUsX2ShBdabUzxWffYw=";
      "atomicwrites-0.4.2" = "sha256-QZSuGPrJXh+svMeFWqAXoqZQxLq/WfIiamqvjJNVhxA=";
      "cosmic-config-0.1.0" = "sha256-lFX/x4Abfk+ZPeFXY02LweMj6bEn+WfGa5e8SAUZGcc=";
      "cosmic-files-0.1.0" = "sha256-mQ5YJXVFTPfzAf6Ugzb16IlJ7pkFjjQqJVXu/Us/XGc=";
      "cosmic-syntax-theme-0.1.0" = "sha256-BNb9wrryD5FJImboD3TTdPRIfiBqPpItqwGdT1ZiNng=";
      "cosmic-text-0.11.2" = "sha256-Y9i5stMYpx+iqn4y5DJm1O1+3UIGp0/fSsnNq3Zloug=";
      "d3d12-0.19.0" = "sha256-usrxQXWLGJDjmIdw1LBXtBvX+CchZDvE8fHC0LjvhD4=";
      "glyphon-0.5.0" = "sha256-j1HrbEpUBqazWqNfJhpyjWuxYAxkvbXzRKeSouUoPWg=";
      "softbuffer-0.4.1" = "sha256-a0bUFz6O8CWRweNt/OxTvflnPYwO5nm6vsyc/WcXyNg=";
      "systemicons-0.7.0" = "sha256-zzAI+6mnpQOh+3mX7/sJ+w4a7uX27RduQ99PNxLNF78=";
      "taffy-0.3.11" = "sha256-SCx9GEIJjWdoNVyq+RZAGn0N71qraKZxf9ZWhvyzLaI=";
      "winit-0.29.10" = "sha256-ScTII2AzK3SC8MVeASZ9jhVWsEaGrSQ2BnApTxgfxK4=";
    };
  };

  postPatch = ''
    substituteInPlace justfile --replace '#!/usr/bin/env' "#!$(command -v env)"
  '';

  nativeBuildInputs = [ just pkg-config makeBinaryWrapper ];
  buildInputs = [
    libxkbcommon
    glib
    gtk3
    xorg.libX11
    libinput
    libglvnd
    fontconfig
    freetype
    wayland
    vulkan-loader
  ];

  dontUseJustBuild = true;

  justFlags = [
    "--set"
    "prefix"
    (placeholder "out")
    "--set"
    "bin-src"
    "target/${stdenv.hostPlatform.rust.cargoShortTarget}/release/cosmic-edit"
  ];

  # Force linking to libEGL, which is always dlopen()ed, and to
  # libwayland-client, which is always dlopen()ed except by the
  # obscure winit backend.
  RUSTFLAGS = map (a: "-C link-arg=${a}") [
    "-Wl,--push-state,--no-as-needed"
    "-lEGL"
    "-lwayland-client"
    "-Wl,--pop-state"
  ];

  # LD_LIBRARY_PATH can be removed once tiny-xlib is bumped above 0.2.2
  postInstall = ''
    wrapProgram "$out/bin/${pname}" \
      --suffix XDG_DATA_DIRS : "${cosmic-icons}/share" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [
        xorg.libX11 xorg.libXcursor xorg.libXi xorg.libXrandr vulkan-loader mesa.drivers
      ]}
  '';

  meta = with lib; {
    homepage = "https://github.com/pop-os/cosmic-edit";
    description = "Text Editor for the COSMIC Desktop Environment";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ ahoneybun nyanbinary ];
    platforms = platforms.linux;
  };
}
