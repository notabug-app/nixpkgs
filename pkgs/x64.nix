{
  final,
  prev,
  inputs,
  versions,
}:
let
  sys = prev.stdenv.hostPlatform.system;
in
prev.lib.optionalAttrs (sys == "x86_64-linux") {
  nvidia-legacy-580 = prev.linuxPackages.nvidiaPackages.legacy_580;
}
