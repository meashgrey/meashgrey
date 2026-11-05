{
  lib,
  stdenvNoCC,
  fetchurl,
  fetchFromGitHub,
  appimage-run,
  makeWrapper,
}:

let
  version = "0.15.2";

  appImage = fetchurl {
    url = "https://github.com/storytold/wordcraft/releases/download/v${version}/wordcraft-${version}-linux-x86_64.AppImage";
    hash = "sha256-dJMrxn/l9TVTBah7eertnlq4NvaF4WM69JkhYeR/gKQ=";
  };

  releaseSource = fetchFromGitHub {
    owner = "storytold";
    repo = "wordcraft";
    rev = "v${version}";
    hash = "sha256-e6L//Dhvziy4d6thhJ9tnjKwiiO+hB9lDq3DOX43Meo=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "wordcraft";
  inherit version;

  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/share/applications" "$out/share/icons"
    makeWrapper ${lib.getExe appimage-run} "$out/bin/wordcraft" \
      --add-flags ${appImage}

    install -Dm644 \
      ${releaseSource}/packaging/linux/ai.storyteller.wordcraft.desktop \
      "$out/share/applications/ai.storyteller.wordcraft.desktop"
    substituteInPlace "$out/share/applications/ai.storyteller.wordcraft.desktop" \
      --replace-fail 'Exec=wordcraft %F' "Exec=$out/bin/wordcraft %F" \
      --replace-fail 'TryExec=wordcraft' "TryExec=$out/bin/wordcraft"

    cp -R ${releaseSource}/assets/app-icon/hicolor "$out/share/icons/"
    install -Dm644 \
      ${releaseSource}/packaging/linux/ai.storyteller.wordcraft.mime.xml \
      "$out/share/mime/packages/ai.storyteller.wordcraft.xml"

    runHook postInstall
  '';

  meta = {
    description = "Open-source word processor";
    homepage = "https://github.com/storytold/wordcraft";
    license = with lib.licenses; [ mit asl20 ];
    mainProgram = "wordcraft";
    platforms = [ "x86_64-linux" ];
  };
}
