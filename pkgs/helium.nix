{
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
  wrapGAppsHook3,
  makeWrapper,
  alsa-lib,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  glib,
  gtk3,
  libdrm,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  systemd,
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxcb,
  wayland,
  versions,
}:
let
  heliumVer = versions.helium;
  version = heliumVer.version;
  sysInfo =
    heliumVer.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
  urlarch = sysInfo.urlarch;
  hash = sysInfo.hash;
in
stdenv.mkDerivation {
  pname = "helium";
  inherit version;

  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-${urlarch}_linux.tar.xz";
    inherit hash;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    wrapGAppsHook3
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    at-spi2-core
    cairo
    cups
    dbus
    expat
    fontconfig
    glib
    gtk3
    libdrm
    libxkbcommon
    mesa
    nspr
    nss
    pango
    systemd
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcb
    wayland
  ];

  autoPatchelfIgnoreMissingDeps = [
    "libQt5Core.so.5"
    "libQt5Gui.so.5"
    "libQt5Widgets.so.5"
    "libQt6Core.so.6"
    "libQt6Gui.so.6"
    "libQt6Widgets.so.6"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/opt/helium
    cp -r * $out/opt/helium/

    makeWrapper $out/opt/helium/helium $out/bin/helium \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ wayland ]}"

    mkdir -p $out/share/applications $out/share/icons/hicolor/256x256/apps
    if [ -f helium.desktop ]; then
      cp helium.desktop $out/share/applications/
      substituteInPlace $out/share/applications/helium.desktop \
        --replace-fail "Exec=helium" "Exec=$out/bin/helium"
    fi

    if [ -f product_logo_256.png ]; then
      cp product_logo_256.png $out/share/icons/hicolor/256x256/apps/helium.png
    fi

    runHook postInstall
  '';

  meta = with lib; {
    description = "Helium browser";
    homepage = "https://github.com/imputnet/helium-linux";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
