{ pkgs ? import <nixpkgs> {inherit system;}
, system ? builtins.currentSystem
, nodejs ? pkgs.nodejs
, nodePackages ? import ../nodePackages { inherit pkgs system nodejs; }
}:
let
  prisma-engines = pkgs.prisma-engines;
  kadena-graph = nodePackages."@kadena/graph".overrideDerivation (attrs: {
    buildInputs = attrs.buildInputs ++ [pkgs.prisma-engines pkgs.makeWrapper];
    PRISMA_SCHEMA_ENGINE_BINARY="${prisma-engines}/bin/schema-engine";
    PRISMA_QUERY_ENGINE_BINARY="${prisma-engines}/bin/query-engine";
    PRISMA_QUERY_ENGINE_LIBRARY="${prisma-engines}/lib/libquery_engine.node";
    PRISMA_INTROSPECTION_ENGINE_BINARY="${prisma-engines}/bin/introspection-engine";
    PRISMA_FMT_BINARY="${prisma-engines}/bin/prisma-fmt";
    postFixup = ''
      wrapProgram $out/bin/kadena-graph \
        --set PRISMA_SCHEMA_ENGINE_BINARY "${prisma-engines}/bin/schema-engine" \
        --set PRISMA_QUERY_ENGINE_BINARY "${prisma-engines}/bin/query-engine" \
        --set PRISMA_QUERY_ENGINE_LIBRARY "${prisma-engines}/lib/libquery_engine.node" \
        --set PRISMA_INTROSPECTION_ENGINE_BINARY "${prisma-engines}/bin/introspection-engine" \
        --set PRISMA_FMT_BINARY "${prisma-engines}/bin/prisma-fmt"
    '';
  });
  kadena-graph-bundle = pkgs.runCommand "kadena-graph" {
    buildInputs = [pkgs.esbuild pkgs.makeWrapper pkgs.removeReferencesTo];
  } ''
    mkdir -p $out
    cp -r ${kadena-graph} drv
    chmod -R +w drv
    cd drv/lib/node_modules/@kadena/graph/node_modules/
    ln -s ../src/db @db
    ln -s ../src/devnet/ @devnet
    ln -s ../src/utils/ @utils
    ln -s ../src/services/ @services
    cd ..
    esbuild ./dist/index.d.ts --bundle --outfile=$out/bin/kadena-graph --format=cjs --platform=node

    prisma_client=lib/node_modules/@kadena/graph/node_modules/@prisma
    mkdir -p $out/$prisma_client
    cp -r ${kadena-graph}/$prisma_client/* $out/$prisma_client
    substituteInPlace $out/bin/kadena-graph \
      --replace ${kadena-graph}/$prisma_client $out/$prisma_client

    wrapProgram $out/bin/kadena-graph \
      --set PRISMA_SCHEMA_ENGINE_BINARY "${prisma-engines}/bin/schema-engine" \
      --set PRISMA_QUERY_ENGINE_BINARY "${prisma-engines}/bin/query-engine" \
      --set PRISMA_QUERY_ENGINE_LIBRARY "${prisma-engines}/lib/libquery_engine.node" \
      --set PRISMA_INTROSPECTION_ENGINE_BINARY "${prisma-engines}/bin/introspection-engine" \
      --set PRISMA_FMT_BINARY "${prisma-engines}/bin/prisma-fmt" \
      --prefix PATH : ${pkgs.nodejs-slim}/bin

    mkdir -p $out/lib/node_modules/@kadena/graph/
    cp -r ${kadena-graph}/lib/node_modules/@kadena/graph/cwd-extra-migrations $out/lib/node_modules/@kadena/graph/
  '';
in {
  inherit nodePackages kadena-graph kadena-graph-bundle;
}
