{
  final,
  prev,
  inputs,
  versions,
}:
let
  sys = prev.stdenv.hostPlatform.system;
in
{
  rustdoc-text = final.callPackage ./rustdoc-text.nix { };
  firn = inputs.firn.packages.${sys}.firn;
}
