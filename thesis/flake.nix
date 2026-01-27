{
  inputs = {
    # nixpkgs.url = "/home/nzbr/Bachelorarbeit/nixpkgs-bootstrap";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    basement = {
      url = "github:nix-prefab/nix-basement/flake-part-stories";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Do not override nixpkgs input here or the caching breaks
    copperflame.url = "github:nzbr/copperflame";
  };

  nixConfig = {
    extra-substituters = [
      "https://nzbr-nix-cache.s3.eu-central-1.wasabisys.com"
    ];
    extra-trusted-public-keys = [
      "nzbr-nix-cache.s3.eu-central-1.wasabisys.com:3BzCCe4Frvvwamd5wibtMAcEKwbVs4y2xKUR2vQ8gIo="
    ];
  };

  outputs = inputs: inputs.basement.lib.constructFlake { inherit inputs; root = ./.; }
  {
    systems = [ "x86_64-linux" ];

    perSystem = { config, self', pkgs, system, ... }: {
      shell = {
        packages = [
          pkgs.coreutils
          pkgs.gnumake
          pkgs.inotify-tools
          pkgs.pandoc
          (pkgs.typst.withPackages (universe: [
            universe.abbr
            universe.codly
            universe.codly-languages
            universe.icu-datetime
            universe.muchpdf
          ]))
          pkgs.umlet
          pkgs.xvfb-run
        ];
        hook = ''
          mkdir -p generated
          ln -sfT ${self'.packages.fonts} generated/fonts
        '';
      };

      packages = {
        default = pkgs.stdenvNoCC.mkDerivation {
          name = "thesis.pdf";

          nativeBuildInputs = config.shell.packages ++ [ pkgs.fontconfig ];

          unpackPhase = ''
            cp -vr ${./assets} assets
            cp -vr ${./Makefile} Makefile
            cp -vr ${./src} src
          '';

          configurePhase = config.shell.hook;

          # Fix the date rendered in the PDF
          # See https://discourse.nixos.org/t/latex-today-macro-expands-to-december-31st-1979/16634/2
          SOURCE_DATE_EPOCH = toString inputs.self.lastModified;

          preBuild = ''
            export HOME=$(mktemp -d)
            export FONTCONFIG_PATH=${pkgs.fontconfig.out}/etc/fonts
            fc-cache
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out
            cp thesis.* $out

            runHook postInstall
          '';
        };

        # LaTeX replaces the proprietary PostScript fonts according to this table: https://tug.ctan.org/fonts/urw/base35/README.base35
        urw-base35 = pkgs.stdenvNoCC.mkDerivation {
          name = "urw-base35";

          src = pkgs.fetchzip {
            url = "https://mirrors.ctan.org/fonts/urw/base35.zip";
            hash = "sha256-OFLmARKIU8ogvMSP4yFrl0BbU2zyMZWjfggw8qtBDWE=";
          };

          nativeBuildInputs = [ pkgs.fontforge ];

          preBuild = ''
            export HOME=$(mktemp -d)
          '';

          buildPhase =
            let
              script = pkgs.writeText "build.ff" ''
                Open("pfb/uagd8a"); Generate("URWGothicL-Demi.otf")
                Open("pfb/uagdo8a"); Generate("URWGothicL-DemiObli.otf")
                Open("pfb/uagk8a"); Generate("URWGothicL-Book.otf")
                Open("pfb/uagko8a"); Generate("URWGothicL-BookObli.otf")
                Open("pfb/ubkd8a"); Generate("URWBookmanL-DemiBold.otf")
                Open("pfb/ubkdi8a"); Generate("URWBookmanL-DemiBoldItal.otf")
                Open("pfb/ubkl8a"); Generate("URWBookmanL-Ligh.otf")
                Open("pfb/ubkli8a"); Generate("URWBookmanL-LighItal.otf")
                Open("pfb/ucrb8a"); Generate("NimbusMonL-Bold.otf")
                Open("pfb/ucrbo8a"); Generate("NimbusMonL-BoldObli.otf")
                Open("pfb/ucrr8a"); Generate("NimbusMonL-Regu.otf")
                Open("pfb/ucrro8a"); Generate("NimbusMonL-ReguObli.otf")
                Open("pfb/uhvb8a"); Generate("NimbusSanL-Bold.otf")
                Open("pfb/uhvb8ac"); Generate("NimbusSanL-BoldCond.otf")
                Open("pfb/uhvbo8a"); Generate("NimbusSanL-BoldItal.otf")
                Open("pfb/uhvbo8ac"); Generate("NimbusSanL-BoldCondItal.otf")
                Open("pfb/uhvr8a"); Generate("NimbusSanL-Regu.otf")
                Open("pfb/uhvr8ac"); Generate("NimbusSanL-ReguCond.otf")
                Open("pfb/uhvro8a"); Generate("NimbusSanL-ReguItal.otf")
                Open("pfb/uhvro8ac"); Generate("NimbusSanL-ReguCondItal.otf")
                Open("pfb/uncb8a"); Generate("CenturySchL-Bold.otf")
                Open("pfb/uncbi8a"); Generate("CenturySchL-BoldItal.otf")
                Open("pfb/uncr8a"); Generate("CenturySchL-Roma.otf")
                Open("pfb/uncri8a"); Generate("CenturySchL-Ital.otf")
                Open("pfb/uplb8a"); Generate("URWPalladioL-Bold.otf")
                Open("pfb/uplbi8a"); Generate("URWPalladioL-BoldItal.otf")
                Open("pfb/uplr8a"); Generate("URWPalladioL-Roma.otf")
                Open("pfb/uplri8a"); Generate("URWPalladioL-Ital.otf")
                Open("pfb/usyr"); Generate("StandardSymL.otf")
                Open("pfb/utmb8a"); Generate("NimbusRomNo9L-Medi.otf")
                Open("pfb/utmbi8a"); Generate("NimbusRomNo9L-MediItal.otf")
                Open("pfb/utmr8a"); Generate("NimbusRomNo9L-Regu.otf")
                Open("pfb/utmri8a"); Generate("NimbusRomNo9L-ReguItal.otf")
                Open("pfb/uzcmi8a"); Generate("URWChanceryL-MediItal.otf")
                Open("pfb/uzdr"); Generate("Dingbats.otf")
              '';
            in
            ''
              runHook preBuild

              fontforge -lang=ff -script ${script}

              runHook postBuild
            '';

          installPhase = ''
            mkdir -p $out/share/fonts/opentype

            cp -vr *.otf $out/share/fonts/opentype
          '';
        };

        charter = pkgs.stdenvNoCC.mkDerivation {
          name = "Bitstream Charter";

          src = pkgs.texlivePackages.charter.tex;

          nativeBuildInputs = [ pkgs.fontforge ];

          unpackPhase = ''
            cp -vr $src/fonts/type1/bitstrea/charter/. .
          '';

          preBuild = ''
            export HOME=$(mktemp -d)
          '';

          buildPhase =
            let
              script = pkgs.writeText "build.ff" ''
                Open("bchb8a"); Generate("BitstramCharter-Bold.otf")
                Open("bchbi8a"); Generate("BitstramCharter-BoldItalic.otf")
                Open("bchr8a"); Generate("BitstramCharter-Regular.otf")
                Open("bchri8a"); Generate("BitstramCharter-Italic.otf")
              '';
            in
            ''
              runHook preBuild

              fontforge -lang=ff -script ${script}

              runHook postBuild
            '';

          installPhase = ''
            mkdir -p $out/share/fonts/opentype

            cp -vr *.otf $out/share/fonts/opentype
          '';
        };

        fonts = pkgs.stdenvNoCC.mkDerivation {
          name = "thesis-fonts";

          buildCommand = ''
            mkdir -p $out

            ln -s ${self'.packages.urw-base35}/share/fonts/opentype/*.otf $out/
            ln -s ${self'.packages.charter}/share/fonts/opentype/*.otf $out/
            ln -s ${inputs.copperflame.packages.${system}.copperflame-mono.unpatched}/share/fonts/truetype/*.ttf $out/
          '';
        };
      };
    };
  };
}
