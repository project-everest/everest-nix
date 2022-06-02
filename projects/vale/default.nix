{ stdenv, fetchzip }:

let

  pname = "vale";
  version = "0.3.16";

in stdenv.mkDerivation rec {
  name = "${pname}-${version}";
  src = fetchzip {
    inherit name;
    url =
      "https://github.com/project-everest/${pname}/releases/download/v${version}/${pname}-release-${version}.zip";
    sha256 = "0dwnw3yb9lan16m6cyzw6s9bxx3jbxydaqk16jsy1ajygj7s6rcr";
  };
  dontBuild = true;
  dontFixup = true;
  installPhase = ''
    cp -r . $out
    ls
    for target in vale importFStarTypes; do
      echo "$DOTNET_JSON_CONF" > $out/bin/$target.runtimeconfig.json
    done
  '';
  DOTNET_JSON_CONF = ''
    {
      "runtimeOptions": {
        "framework": {
          "name": "Microsoft.NETCore.App",
          "version": "6.0.0"
        }
      }
    }'';
}
