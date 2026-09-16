{
  lib,
  dockerTools,
  system,
}:

let
  sources = import ./sources-images.nix;

  _supported = lib.assertMsg (builtins.elem system [
    "x86_64-linux"
    "aarch64-linux"
  ]) "unsupported FloCI image platform: ${system}";

  mkImage =
    sourceKey:
    let
      sourceSet = sources.${sourceKey};
      _platformSupported = lib.assertMsg (builtins.hasAttr system sourceSet) "${sourceKey} is not published for ${system}";
      source = sourceSet.${system};
      _initialized =
        lib.assertMsg (source.hash != lib.fakeHash)
          "sources-images.nix is not initialized for ${sourceKey}/${system}; run ./scripts/update-sources first";
    in
    assert _platformSupported;
    assert _initialized;
    dockerTools.pullImage {
      inherit (source)
        imageName
        imageDigest
        hash
        finalImageName
        finalImageTag
        arch
        ;
      os = "linux";
    };
in
assert _supported;
{
  aws = mkImage "aws";
  awsCompat = mkImage "aws-compat";
  azure = mkImage "azure";
  gcp = mkImage "gcp";
  oci = mkImage "oci";
  ociCompat = mkImage "oci-compat";
}
// lib.optionalAttrs (system == "aarch64-linux") {
  awsBaseline = mkImage "aws-baseline";
}
