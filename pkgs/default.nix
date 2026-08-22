{
  final,
  prev,
  inputs,
  versions,
}:
let
  args = {
    inherit
      final
      prev
      inputs
      versions
      ;
  };
in
(import ./common.nix args) // (import ./x64.nix args) // (import ./arm.nix args)
