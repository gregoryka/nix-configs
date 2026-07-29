{
  self,
}:
let
  inherit (self.lib) base64;
in
{
  # base64.decode
  testBase64DecodeHello = {
    expr = base64.decode "aGVsbG8=";
    expected = "hello";
  };

  testBase64DecodeNoPadding = {
    expr = base64.decode "Zm9vYmFy";
    expected = "foobar";
  };

  testBase64DecodeOnePad = {
    expr = base64.decode "Zm9vYmE=";
    expected = "fooba";
  };

  testBase64DecodeTwoPad = {
    expr = base64.decode "Zm9vYg==";
    expected = "foob";
  };

  # Regression test: bytes >= 128 were previously decoded incorrectly
  # because lib/base64/ascii was generated with UTF-8 (multi-byte for
  # codepoints 128-255) instead of latin-1 (1 byte per codepoint). Compares
  # against a raw single-byte fixture file rather than a Nix string literal,
  # since Nix has no \xNN escape and the source file's own encoding would
  # otherwise reintroduce the same multi-byte problem being tested for.
  testBase64DecodeHighByte = {
    expr = base64.decode "yA==";
    expected = builtins.readFile ./fixtures/latin1-c8;
  };
}
