{ pkgs ? import <nixpkgs> {inherit system;}
, system ? builtins.currentSystem
, nodejs ? pkgs.nodejs
, nodejs-slim ? pkgs.nodejs-slim
, rollup ? pkgs.nodePackages.rollup
, nodePackages ? import ../nodePackages { inherit pkgs system nodejs; }
}:
with pkgs.lib;
let
  clibundle = nodePackages."clibundle-../kadena-cli";
  kadena-cli-archive = lists.findSingle
    (d: d.packageName == "@kadena/kadena-cli")
    (builtins.abort "@kadena/kadena-cli not found in clibundle dependencies")
    (builtins.abort "Multiple @kadena/kadena-cli found in clibundle dependencies")
    clibundle.dependencies;
  kadena-cli-bundled = pkgs.stdenv.mkDerivation rec {
    inherit (kadena-cli-archive) version packageName;
    buildInputs = [rollup pkgs.makeWrapper pkgs.removeReferencesTo];
    name = "kadena-${version}";
    enableParallelBuilding = true;
    passAsFile = [ "buildCommand" ];
    buildCommand = ''
      mkdir -p $out
      cp -r ${clibundle} clibundle
      chmod -R +w clibundle

      KADENACLI="clibundle/lib/node_modules/clibundle/"

      ( cd "$KADENACLI" &&
        rollup -c rollup.config.mjs
      )

      mkdir -p $out/lib
      cp $KADENACLI/lib/cli.mjs $out/lib/cli.mjs
      cp $KADENACLI/package.json $out/package.json

      remove-references-to -t ${clibundle} $out/lib/cli.mjs

      mkdir -p $out/bin
      cat - > $out/bin/kadena <<EOF
      #!${pkgs.runtimeShell}
      ${nodejs-slim}/bin/node $out/lib/cli.mjs "\$@"
      EOF
      chmod +x $out/bin/kadena
    '';
  };
in {
  inherit nodePackages kadena-cli-bundled;
}
