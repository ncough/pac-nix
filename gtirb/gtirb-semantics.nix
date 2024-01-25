{ lib
, fetchFromGitHub
, protobuf
, asli
, buildDunePackage
, ocaml-protoc-plugin
, ocaml-hexstring
, base64
, yojson
, writeShellApplication
, makePythonPth
, python3Packages
}:

let
  wrapper = writeShellApplication {
    name = "gtirb-semantics-wrapper";
    text = ''
      # gtirb-semantics-wrapper: wrapper script for executing gtirb_semantics when packaged by Nix.
      # this inserts the required ASLI arguments, and passes through the user's input/output arguments.

      prog="$(dirname "$0")"/gtirb_semantics
      input="$1"
      shift
      
      echo '$' "$(basename "$prog")" "$input" ${baseNameOf asli.prelude} ${baseNameOf asli.mra_tools}/ ${baseNameOf asli.dir}/ "$@" >&2
      "$prog" "$input" ${asli.prelude} ${asli.mra_tools} ${asli.dir} "$@"
    '';
  };

  pth = makePythonPth python3Packages "gtirb-semantics" [ protobuf ];
  python' = python3Packages.python.withPackages 
    (_: [ python3Packages.protobuf pth ]);

in
buildDunePackage {
  pname = "gtirb_semantics";
  version = "unstable-2024-01-24";

  src = fetchFromGitHub {
    owner = "UQ-PAC";
    repo = "gtirb-semantics";
    rev = "c65af262e6b9396792e24896cbf69d2cd77f4b07";
    sha256 = "sha256-XghS2DT50prDw3crUyuFp1zm9vtyY/Jf/Sg3UyG5K5o=";
  };

  buildInputs = [ python' asli ocaml-hexstring ocaml-protoc-plugin yojson ];
  nativeBuildInputs = [ protobuf ocaml-protoc-plugin ];
  propagatedBuildInputs = [ base64 ];

  postInstall = ''
    ln -sv ${wrapper}/bin/* $out/bin/gtirb-semantics-nix
    cp -v $src/scripts/*.py $out/bin 
  '';

  outputs = [ "out" "dev" ];

  meta = {
    homepage = "https://github.com/UQ-PAC/gtirb-semantics";
    description = "Add instruction semantics to the IR of a dissassembled ARM64 binary";
    maintainers = [ "Kait Lam <k@rina.fyi>" ];
  };
}
