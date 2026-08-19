{
  final,
  prev,
  inputs,
}:
let
  args = { inherit final prev inputs; };
in
(import ./common.nix args) // (import ./x64.nix args) // (import ./arm.nix args)
