{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  makeWrapper,
  jdk17_headless,
  android-tools,
  jadx,
}:

let
  version = "0.4.1";
  portableArchive = fetchurl {
    url = "https://github.com/Verlintas/NOIR/releases/download/v${version}/noir-v${version}-Linux-portable.zip";
    hash = "sha256-NWe1l1pD8AB78CQIZzZj++EfHiVRAvqknGxygI3A0KU=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "noir";
  inherit version;

  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [ unzip makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/noir" "$out/bin"
    unzip -q -j ${portableArchive} 'NOIR/lib/app/*.jar' -d "$out/share/noir"
    classpath="$(printf '%s:' "$out"/share/noir/*.jar)"
    classpath="''${classpath%:}"

    makeWrapper ${jdk17_headless}/bin/java "$out/bin/noir" \
      --add-flags "-Dfile.encoding=UTF-8 -cp $classpath app.noir.cli.MainKt" \
      --prefix PATH : ${lib.makeBinPath [ android-tools jadx ]}

    runHook postInstall
  '';

  meta = {
    description = "Android application privacy and telemetry auditor";
    homepage = "https://github.com/Verlintas/NOIR";
    license = lib.licenses.mit;
    mainProgram = "noir";
    platforms = [ "x86_64-linux" ];
  };
}
