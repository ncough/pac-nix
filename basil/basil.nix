{ lib
, fetchFromGitHub
, mkSbtDerivation
, makeBinaryWrapper
, jdk
, jre
, testers
, basil
}:

mkSbtDerivation {
  pname = "basil";
  version = "0.1.2-alpha-unstable-2024-09-18";

  nativeBuildInputs = [ jdk makeBinaryWrapper ];

  src = fetchFromGitHub {
    owner = "UQ-PAC";
    repo = "bil-to-boogie-translator";
    rev = "3030d6bb2e42437799f7e6c3648329ef3503794b";
    sha256 = "sha256-l9LQrjpzUvtvjAnS7qqA0S81G4wD6dqYTTnCPmMIKB4=";
  };

  depsSha256 = "sha256-++gg+SKskDyaqHowNG2RPS7evuCzPYvvXMC4Rkp7b6U=";

  buildPhase = ''
    javac -version
    sbt assembly
  '';

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/share/basil

    JAR="$(echo target/scala*/wptool-boogie*.jar)"

    if ! [[ -f "$JAR" ]]; then
      echo "ERROR: basil jar file not found!" >&2
      ls -l target/scala*
      false
    fi

    # copy jar to output directory
    cp -v "$JAR" $out/share/basil/$(basename $JAR)

    # make wrapper to run jar with appropriate arguments
    makeWrapper "${lib.getExe jre}" $out/bin/basil \
      --add-flags -jar \
      --add-flags "$out/share/basil/$(basename $JAR)"
  '';

  meta = {
    homepage = "https://github.com/UQ-PAC/bil-to-boogie-translator";
    description = "Basil static analysis tool to analyse and translate BIR to Boogie.";
    maintainers = with lib.maintainers; [ katrinafyi ];
  };

  passthru.tests.basil-arg = testers.testVersion {
    package = basil;
    command = ''basil --help'';
    version = ''analyse'';
  };
}
