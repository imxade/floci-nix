{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  jdk25_headless,
}:

let
  source = import ./source-cli.nix;

  _sourceIsInitialized = lib.assertMsg (
    source.hash != lib.fakeHash
  ) "source-cli.nix is not initialized; run ./scripts/update-sources first";

  src = fetchurl {
    inherit (source) url hash;
    name = "floci-${source.version}.jar";
  };
in
assert _sourceIsInitialized;
stdenvNoCC.mkDerivation {
  pname = "floci-cli";
  inherit (source) version;
  inherit src;

  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    install -Dm444 "$src" "$out/share/floci/floci.jar"
    makeWrapper ${jdk25_headless}/bin/java "$out/bin/floci" \
      --add-flags "-jar $out/share/floci/floci.jar" \
      --set FLOCI_NO_UPDATE_CHECK 1

    runHook postInstall
  '';

  meta = {
    description = "Official CLI for the FloCI local cloud emulators";
    homepage = "https://github.com/floci-io/floci-cli";
    license = lib.licenses.mit;
    mainProgram = "floci";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
  };
}
