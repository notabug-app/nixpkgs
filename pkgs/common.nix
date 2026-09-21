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
  helium = prev.callPackage ./helium.nix { inherit versions; };
  rustdoc-text = prev.callPackage ./rustdoc-text.nix { };
}
