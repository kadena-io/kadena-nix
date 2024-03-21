{ pkgs ? import <nixpkgs> {inherit system;}
, system ? builtins.currentSystem
, nodePackages ? import ../nodePackages { inherit pkgs system; }
, nodejs ? pkgs.nodejs
}:
let
  kadena-client-bundle = pkgs.runCommand "kadena-client-bundle" {
    buildInputs = [pkgs.esbuild];
  } ''
    mkdir -p $out/@kadena/client
    cd ${nodePackages."@kadena/client"}/lib/node_modules/@kadena/client/
    esbuild lib/index.d.ts \
      --bundle --platform=node --format=cjs \
      --external:@kadena/types \
      --outfile=$out/@kadena/client/index.js
    mkdir -p $out/@kadena/types
    echo "module.exports = {};" > $out/@kadena/types/index.js
  '';
  kadena-client = pkgs.writeShellScriptBin "kadena-client" ''
    export NODE_PATH=${kadena-client-bundle}:$NODE_PATH
    exec ${nodejs}/bin/node "$@"
  '';
in {
  inherit kadena-client-bundle kadena-client;
}