{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  glibc,
  stdenv,
  steam,
}:

let
  version = "0.4.6";
  unwrapped = stdenvNoCC.mkDerivation {
    pname = "steam-tui";
    inherit version;

    src = fetchurl {
      url = "https://github.com/vanyapoker/steam-tui/releases/download/v${version}/steam-tui-x86_64-linux.tar.gz";
      hash = "sha256-98emLM1DQz5L4auef5B0CSG0d74DzNmCnIyHIS/vQSk=";
    };

    dontUnpack = true;
    dontBuild = true;

    nativeBuildInputs = [ autoPatchelfHook ];
    buildInputs = [ glibc stdenv.cc.cc.lib ];

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      tar -xzf "$src" -C "$out"
      runHook postInstall
    '';

    meta = {
      description = "Terminal Steam client with its own library and game launcher";
      homepage = "https://github.com/vanyapoker/steam-tui";
      license = lib.licenses.mit;
      mainProgram = "steam-tui";
      platforms = [ "x86_64-linux" ];
    };
  };
in
# pressure-vessel needs an FHS host (including /usr/bin/true and ld.so.cache).
# Patching the launcher ELF alone does not provide that environment on NixOS.
steam.buildRuntimeEnv {
  pname = "steam-tui";
  inherit version;
  inherit (unwrapped) meta;

  extraPkgs = _: [ unwrapped ];
  runScript = "${unwrapped}/bin/steam-tui";
  executableName = "steam-tui";
  # CLI launches return while the game is still running.
  dieWithParent = false;

  extraInstallCommands = ''
    ln -s ${unwrapped}/lib $out/lib
    ln -s ${unwrapped}/share $out/share
  '';
}
