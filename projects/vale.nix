{ fetchzip }:

let

  pname = "vale";
  version = "0.3.16";

in

fetchzip {
  name = "${pname}-${version}";
  url = "https://github.com/project-everest/${pname}/releases/download/v${version}/${pname}-release-${version}.zip";
  sha256 = "0dwnw3yb9lan16m6cyzw6s9bxx3jbxydaqk16jsy1ajygj7s6rcr";
}
