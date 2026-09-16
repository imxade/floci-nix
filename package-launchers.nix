{
  lib,
  writeShellApplication,
  docker,
  system,
  cli,
  images,
}:

let
  sources = import ./sources-images.nix;

  mkLauncher =
    {
      sourceKey,
      product,
      binaryName,
      cliGroup,
      image,
    }:
    let
      source = sources.${sourceKey}.${system};
      imageRef = "${source.finalImageName}:${source.finalImageTag}";
      cliPrefix = if cliGroup == "" then "" else "${cliGroup} ";
    in
    writeShellApplication {
      name = binaryName;
      runtimeInputs = [
        cli
        docker
      ];
      text = ''
        image_ref=${lib.escapeShellArg imageRef}
        image_tar=${lib.escapeShellArg (toString image)}

        ensure_image() {
          if ! docker image inspect "$image_ref" >/dev/null 2>&1; then
            printf 'Loading pinned FloCI image %s into Docker...\n' "$image_ref" >&2
            docker image load --input "$image_tar" >/dev/null
          fi
        }

        if (( $# == 0 )); then
          command_name=start
        else
          command_name=$1
          shift
        fi

        case "$command_name" in
          start|restart)
            ensure_image
            exec floci ${cliPrefix}"$command_name" --image "$image_ref" "$@"
            ;;
          image)
            printf '%s\n' "$image_ref"
            ;;
          load)
            ensure_image
            printf '%s\n' "$image_ref"
            ;;
          *)
            exec floci ${cliPrefix}"$command_name" "$@"
            ;;
        esac
      '';
      meta = {
        description = "FloCI ${product} launcher using the Nix-pinned ${sourceKey} image";
        homepage = "https://github.com/floci-io";
        license = lib.licenses.mit;
        mainProgram = binaryName;
        platforms =
          if sourceKey == "aws-baseline" then
            [ "aarch64-linux" ]
          else
            [
              "x86_64-linux"
              "aarch64-linux"
            ];
      };
    };
in
{
  floci-aws = mkLauncher {
    sourceKey = "aws";
    product = "AWS";
    binaryName = "floci-aws";
    cliGroup = "";
    image = images.aws;
  };

  floci-aws-compat = mkLauncher {
    sourceKey = "aws-compat";
    product = "AWS compat";
    binaryName = "floci-aws-compat";
    cliGroup = "";
    image = images.awsCompat;
  };

  floci-az = mkLauncher {
    sourceKey = "azure";
    product = "Azure";
    binaryName = "floci-az";
    cliGroup = "az";
    image = images.azure;
  };

  floci-gcp = mkLauncher {
    sourceKey = "gcp";
    product = "GCP";
    binaryName = "floci-gcp";
    cliGroup = "gcp";
    image = images.gcp;
  };

  floci-oci = mkLauncher {
    sourceKey = "oci";
    product = "OCI";
    binaryName = "floci-oci";
    cliGroup = "oci";
    image = images.oci;
  };

  floci-oci-compat = mkLauncher {
    sourceKey = "oci-compat";
    product = "OCI compat";
    binaryName = "floci-oci-compat";
    cliGroup = "oci";
    image = images.ociCompat;
  };
}
// lib.optionalAttrs (system == "aarch64-linux") {
  floci-aws-baseline = mkLauncher {
    sourceKey = "aws-baseline";
    product = "AWS ARM64 baseline";
    binaryName = "floci-aws-baseline";
    cliGroup = "";
    image = images.awsBaseline;
  };
}
