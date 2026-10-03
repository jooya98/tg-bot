{
  lib,
  stdenv,
  python3,
  makeWrapper,
  yt-dlp,
  ffmpeg,
  playwright-driver,
  # Headless-Chromium fallback for JS-only players (opt-in: large closure).
  withBrowser ? false,
}:

let
  pythonEnv = python3.withPackages (
    ps:
    [
      ps.aiogram
      ps.aiohttp
      ps.python-dotenv
      ps.structlog
    ]
    ++ lib.optional withBrowser ps.playwright
  );
in
stdenv.mkDerivation {
  pname = "tgBot";
  # Keep in sync with the release tag (and packaging/aur/PKGBUILD).
  version = "0.6.0";

  src = lib.fileset.toSource {
    root = ../..;
    fileset = lib.fileset.unions [
      ../../main.py
      ../../src
    ];
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/tgBot
    cp -r main.py src $out/share/tgBot/
    makeWrapper ${pythonEnv.interpreter} $out/bin/tgBot \
      --add-flags $out/share/tgBot/main.py \
      --prefix PATH : ${
        lib.makeBinPath [
          yt-dlp
          ffmpeg
        ]
      } ${
        lib.optionalString withBrowser "--set-default PLAYWRIGHT_BROWSERS_PATH ${playwright-driver.browsers}"
      }
    runHook postInstall
  '';

  meta = {
    description = "Adaptive Telegram crawler/downloader foundation (yt-dlp + aiogram)";
    homepage = "https://github.com/jooya98/tg-bot";
    license = lib.licenses.mit;
    mainProgram = "tgBot";
    platforms = lib.platforms.linux;
  };
}
