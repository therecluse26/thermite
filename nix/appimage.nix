# The Thermite window from a release AppImage. It runs the AppImage through appimage-run,
# as the AppImage binfmt handler does, so nothing is built. The desktop entry and the
# icons come from this repository, like those in the AppImage.
{
  lib,
  appimage-run,
  makeDesktopItem,
  runCommand,
  runtimeShell,
  # The release AppImage. module.nix gives the one in release.json.
  appimage,
}:

let
  # The AppImage has libgcrypt but not libgpg-error, which libgcrypt needs. AppImages
  # expect libgpg-error on the host, and the appimage-run environment does not have it.
  appimage-run' = appimage-run.override { extraPkgs = pkgs: [ pkgs.libgpg-error ]; };
  icons = ../src-tauri/icons;
  desktopItem = makeDesktopItem {
    name = "thermite";
    desktopName = "Thermite";
    comment = "Temperature charts for every hardware sensor";
    exec = "thermite";
    icon = "thermite";
    categories = [ "Utility" ];
    startupWMClass = "thermite";
  };
in
runCommand "thermite" { meta.mainProgram = "thermite"; } ''
  # An executable copy. Without the fan daemon, the window starts its fan helper as
  # `pkexec $APPIMAGE --fan-helper`, and appimage-run sets APPIMAGE to this file.
  install -Dm555 ${appimage} $out/libexec/thermite/thermite.AppImage

  mkdir -p $out/bin
  cat > $out/bin/thermite <<EOF
  #!${runtimeShell}
  exec ${lib.getExe appimage-run'} $out/libexec/thermite/thermite.AppImage "\$@"
  EOF
  chmod 555 $out/bin/thermite

  install -Dm444 -t $out/share/applications ${desktopItem}/share/applications/thermite.desktop
  for size in 32x32 64x64 128x128; do
    install -Dm444 ${icons}/$size.png $out/share/icons/hicolor/$size/apps/thermite.png
  done
  install -Dm444 ${icons}/128x128@2x.png $out/share/icons/hicolor/256x256/apps/thermite.png
''
