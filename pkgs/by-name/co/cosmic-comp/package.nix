{ lib
, stdenv
, rustPlatform
, fetchFromGitHub
, makeBinaryWrapper
, pkg-config
, libinput
, libglvnd
, libxkbcommon
, mesa
, seatd
, udev
, xwayland
, wayland
, xorg
, useXWayland ? true
, systemd
, useSystemd ? lib.meta.availableOn stdenv.hostPlatform systemd
, cosmic-settings
, cosmic-icons
}:

rustPlatform.buildRustPackage {
  pname = "cosmic-comp";
  version = "0-unstable-2024-02-24";

  src = fetchFromGitHub {
    owner = "pop-os";
    repo = "cosmic-comp";
    rev = "e83796680f66be0b19905bd895e8df2815a6d961";
    hash = "sha256-Lj24AkdLHOICHnBtrVCTKaBiySViTCxEWl4Ry8nfiXg=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "atomicwrites-0.4.2" = "sha256-QZSuGPrJXh+svMeFWqAXoqZQxLq/WfIiamqvjJNVhxA=";
      "cosmic-config-0.1.0" = "sha256-uo4So9I/jD3LPfigyKwESUdZiK1wqm7rg9wYwyv4uKc=";
      "cosmic-protocols-0.1.0" = "sha256-vj7Wm1uJ5ULvGNEwKznNhujCZQiuntsWMyKQbIVaO/Q=";
      "cosmic-text-0.10.0" = "sha256-S0GkKUiUsSkL1CZHXhtpQy7Mf5+6fqNuu33RRtxG3mE=";
      "glyphon-0.4.1" = "sha256-mwJXi63LTBIVFrFcywr/NeOJKfMjQaQkNl3CSdEgrZc=";
      "id_tree-1.8.0" = "sha256-uKdKHRfPGt3vagOjhnri3aYY5ar7O3rp2/ivTfM2jT0=";
      "smithay-0.3.0" = "sha256-6nhOQMsiogHt6Bw4zSSSbJXDlKTJdz+TT3yN5aKxcgU=";
      "smithay-egui-0.1.0" = "sha256-FcSoKCwYk3okwQURiQlDUcfk9m/Ne6pSblGAzHDaVHg=";
      "softbuffer-0.3.3" = "sha256-eKYFVr6C1+X6ulidHIu9SP591rJxStxwL9uMiqnXx4k=";
      "taffy-0.3.11" = "sha256-SCx9GEIJjWdoNVyq+RZAGn0N71qraKZxf9ZWhvyzLaI=";
    };
  };

  #separateDebugInfo = true;

  nativeBuildInputs = [ makeBinaryWrapper pkg-config ];
  buildInputs = [
      libglvnd
      libinput
      libxkbcommon
      mesa
      seatd
      udev
      wayland
    ] ++ lib.optional useSystemd systemd;

  # Only default feature is systemd
  buildNoDefaultFeatures = !useSystemd;

  # Force linking to libEGL, which is always dlopen()ed, and to
  # libwayland-client, which is always dlopen()ed except by the
  # obscure winit backend.
  RUSTFLAGS = map (a: "-C link-arg=${a}") [
    "-Wl,--push-state,--no-as-needed"
    "-lEGL"
    "-lwayland-client"
    "-Wl,--pop-state"
  ];

  # These libraries are only used by the X11 backend, which will not
  # be the common case, so just make them available, don't link them.
  postInstall = ''
    mkdir -p $out/etc/cosmic-comp
    cp config.ron $out/etc/cosmic-comp/config.ron
    wrapProgramArgs=(--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [
        xorg.libX11 xorg.libXcursor xorg.libXi xorg.libXrandr
    ]})
  '' + lib.optionalString useXWayland ''
    wrapProgramArgs+=(--prefix PATH : ${lib.makeBinPath [ xwayland ]})
  '' + ''
    wrapProgram $out/bin/cosmic-comp "''${wrapProgramArgs[@]}" \
      --suffix XDG_CONFIG_DIRS : $out/etc \
      --suffix XDG_DATA_DIRS : ${cosmic-settings}/share:${cosmic-icons}/share
  '';

  meta = with lib; {
    homepage = "https://github.com/pop-os/cosmic-comp";
    description = "Compositor for the COSMIC Desktop Environment";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ qyliss nyanbinary ];
    platforms = platforms.linux;
  };
}
