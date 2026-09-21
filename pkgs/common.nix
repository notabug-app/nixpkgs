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
  rusty-man = prev.callPackage ./rusty-man.nix { };
}
