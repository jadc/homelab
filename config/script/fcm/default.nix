{ pkgs, ... }:

let
    instagrapi = pkgs.python3Packages.buildPythonPackage {
        pname = "instagrapi";
        version = "2.2.1";
        src = pkgs.fetchPypi {
            pname = "instagrapi";
            version = "2.2.1";
            hash = "";
        };
        propagatedBuildInputs = with pkgs.python3Packages; [
            requests
            pysocks
            pydantic
            moviepy
            pycryptodomex
        ];
    };

    instarec = pkgs.python3Packages.buildPythonPackage {
        pname = "instarec";
        version = "0.0.1";
        src = pkgs.fetchFromGitHub {
            owner = "qwer-lives";
            repo = "instarec";
            rev = "main";
            hash = "";
        };
        propagatedBuildInputs = with pkgs.python3Packages; [
            aiohttp-socks
            aiofiles
            aiohttp
            pysocks
            tqdm
            lxml
            instagrapi
        ];
    };

    python = pkgs.python3.withPackages (ps: [ instarec ]);

    fcm = pkgs.stdenv.mkDerivation {
        name = "fcm";
        src = ./.;
        nativeBuildInputs = [ pkgs.makeWrapper ];
        installPhase = ''
            mkdir -p $out/bin
            cp fcm.py $out/bin/fcm
            chmod +x $out/bin/fcm
            sed -i '1i #!${python}/bin/python3' $out/bin/fcm
            wrapProgram $out/bin/fcm \
                --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.ffmpeg python ]}
        '';
    };
in
{
    environment.systemPackages = [ fcm ];
}
