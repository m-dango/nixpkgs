{ lib
, stdenv
, autoPatchelfHook
, makeWrapper
, perl
, unzip
, zlib
}:
{ product
, javaVersion
, extraBuildInputs ? [ ]
, meta ? { }
, passthru ? { }
, ... } @ args:

stdenv.mkDerivation (args // {
  pname = "${product}-java${javaVersion}";

  nativeBuildInputs = [ perl unzip makeWrapper ]
    ++ lib.optional stdenv.hostPlatform.isLinux autoPatchelfHook;

  buildInputs = [
    stdenv.cc.cc.lib # libstdc++.so.6
    zlib
  ] ++ extraBuildInputs;

  unpackPhase = ''
    runHook preUnpack

    unpack_jar() {
      local jar="$1"
      unzip -q -o "$jar" -d "$out"
      perl -ne 'use File::Path qw(make_path);
                use File::Basename qw(dirname);
                if (/^(.+) = (.+)$/) {
                  make_path dirname("$ENV{out}/$1");
                  symlink $2, "$ENV{out}/$1";
                }' "$out/META-INF/symlinks"
      perl -ne 'if (/^(.+) = ([r-])([w-])([x-])([r-])([w-])([x-])([r-])([w-])([x-])$/) {
                  my $mode = ($2 eq 'r' ? 0400 : 0) + ($3 eq 'w' ? 0200 : 0) + ($4  eq 'x' ? 0100 : 0) +
                              ($5 eq 'r' ? 0040 : 0) + ($6 eq 'w' ? 0020 : 0) + ($7  eq 'x' ? 0010 : 0) +
                              ($8 eq 'r' ? 0004 : 0) + ($9 eq 'w' ? 0002 : 0) + ($10 eq 'x' ? 0001 : 0);
                  chmod $mode, "$ENV{out}/$1";
                }' "$out/META-INF/permissions"
      rm -rf "$out/META-INF"
    }

    mkdir -p "$out"

    unpack_jar "$src"

    runHook postUnpack
  '';

  dontInstall = true;
  dontBuild = true;
  dontStrip = true;

  passthru = { inherit product; } // passthru;

  meta = with lib; ({
    homepage = "https://www.graalvm.org/";
    description = "High-Performance Polyglot VM (Product: ${product})";
    license = with licenses; [ upl gpl2Classpath bsd3 ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    maintainers = with maintainers; [
      bandresen
      hlolli
      glittershark
      babariviere
      ericdallo
      thiagokokada
    ];
  } // meta);
})
