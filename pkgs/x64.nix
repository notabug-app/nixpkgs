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
  noctalia = inputs.noctalia.packages.${sys}.default;
  noctalia-greeter = inputs.noctalia-greeter.packages.${sys}.default;
  nvidia-legacy-580 = prev.linuxPackages.nvidiaPackages.legacy_580;
}
