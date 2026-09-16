{
  description = "Reproducible Nix packages for every stable FloCI cloud-emulator release variant, with automatic upstream updates";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = lib.genAttrs supportedSystems;
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          cli = pkgs.callPackage ./package-cli.nix { };
          images = pkgs.callPackage ./package-images.nix { inherit system; };
          launchers = pkgs.callPackage ./package-launchers.nix {
            inherit system cli images;
          };
        in
        {
          floci = cli;
          inherit (launchers)
            floci-aws
            floci-aws-compat
            floci-az
            floci-gcp
            floci-oci
            floci-oci-compat
            ;

          aws-image = images.aws;
          aws-compat-image = images.awsCompat;
          azure-image = images.azure;
          gcp-image = images.gcp;
          oci-image = images.oci;
          oci-compat-image = images.ociCompat;

          default = cli;
        }
        // lib.optionalAttrs (system == "aarch64-linux") {
          floci-aws-baseline = launchers.floci-aws-baseline;
          aws-baseline-image = images.awsBaseline;
        }
      );

      apps = forAllSystems (
        system:
        let
          p = self.packages.${system};
        in
        {
          floci = {
            type = "app";
            program = "${p.floci}/bin/floci";
            meta.description = "FloCI CLI";
          };
          aws = {
            type = "app";
            program = "${p.floci-aws}/bin/floci-aws";
            meta.description = "FloCI AWS launcher";
          };
          aws-compat = {
            type = "app";
            program = "${p.floci-aws-compat}/bin/floci-aws-compat";
            meta.description = "FloCI AWS compat launcher";
          };
          azure = {
            type = "app";
            program = "${p.floci-az}/bin/floci-az";
            meta.description = "FloCI Azure launcher";
          };
          gcp = {
            type = "app";
            program = "${p.floci-gcp}/bin/floci-gcp";
            meta.description = "FloCI GCP launcher";
          };
          oci = {
            type = "app";
            program = "${p.floci-oci}/bin/floci-oci";
            meta.description = "FloCI OCI launcher";
          };
          oci-compat = {
            type = "app";
            program = "${p.floci-oci-compat}/bin/floci-oci-compat";
            meta.description = "FloCI OCI compat launcher";
          };
          default = {
            type = "app";
            program = "${p.floci}/bin/floci";
            meta.description = "FloCI CLI";
          };
        }
        // lib.optionalAttrs (system == "aarch64-linux") {
          aws-baseline = {
            type = "app";
            program = "${p.floci-aws-baseline}/bin/floci-aws-baseline";
            meta.description = "FloCI AWS baseline launcher";
          };
        }
      );

      overlays.default =
        final: _prev:
        let
          system = final.stdenv.hostPlatform.system;
          cli = final.callPackage ./package-cli.nix { };
          images = final.callPackage ./package-images.nix { inherit system; };
          launchers = final.callPackage ./package-launchers.nix {
            inherit system cli images;
          };
        in
        {
          floci = cli;
          inherit (launchers)
            floci-aws
            floci-aws-compat
            floci-az
            floci-gcp
            floci-oci
            floci-oci-compat
            ;
          floci-aws-image = images.aws;
          floci-aws-compat-image = images.awsCompat;
          floci-azure-image = images.azure;
          floci-gcp-image = images.gcp;
          floci-oci-image = images.oci;
          floci-oci-compat-image = images.ociCompat;
        }
        // lib.optionalAttrs (system == "aarch64-linux") {
          floci-aws-baseline = launchers.floci-aws-baseline;
          floci-aws-baseline-image = images.awsBaseline;
        };

      checks = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          p = self.packages.${system};
        in
        {
          cli = p.floci;
          aws-image = p.aws-image;
          aws-compat-image = p.aws-compat-image;
          azure-image = p.azure-image;
          gcp-image = p.gcp-image;
          oci-image = p.oci-image;
          oci-compat-image = p.oci-compat-image;

          package-layout = pkgs.runCommand "floci-package-layout" { } ''
            test -x ${p.floci}/bin/floci
            test -x ${p.floci-aws}/bin/floci-aws
            test -x ${p.floci-aws-compat}/bin/floci-aws-compat
            test -x ${p.floci-az}/bin/floci-az
            test -x ${p.floci-gcp}/bin/floci-gcp
            test -x ${p.floci-oci}/bin/floci-oci
            test -x ${p.floci-oci-compat}/bin/floci-oci-compat
            touch "$out"
          '';

          shellcheck =
            pkgs.runCommand "floci-shellcheck"
              {
                nativeBuildInputs = [ pkgs.shellcheck ];
              }
              ''
                shellcheck ${./scripts/update-sources}
                shellcheck ${./scripts/check-sources}
                shellcheck ${./scripts/validate-local}
                touch "$out"
              '';

          actionlint =
            pkgs.runCommand "floci-actionlint"
              {
                nativeBuildInputs = [ pkgs.actionlint ];
              }
              ''
                actionlint \
                  ${./.github/workflows/ci.yml} \
                  ${./.github/workflows/update-floci.yml} \
                  ${./.github/workflows/maintenance.yml}
                touch "$out"
              '';
        }
        // lib.optionalAttrs (system == "aarch64-linux") {
          aws-baseline-image = p.aws-baseline-image;
        }
      );

      formatter = forAllSystems (system: (pkgsFor system).nixfmt);

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              actionlint
              curl
              git
              jq
              nix-prefetch-docker
              nixfmt
              python3
              shellcheck
              skopeo
            ];
          };
        }
      );
    };
}
