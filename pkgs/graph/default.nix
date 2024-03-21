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

  prisma-slim = pkgs.runCommand "prisma-slim" {} ''
    mkdir -p $out
    cp -r ${prisma-engines}/lib $out/lib
  '';

  kadena-graph-bundle = pkgs.runCommand "kadena-graph" {
    buildInputs = [pkgs.esbuild pkgs.makeWrapper pkgs.removeReferencesTo];
  } ''
    mkdir -p $out
    cp -r ${kadena-graph} kadena-graph
    chmod -R +w kadena-graph

    GRAPH="kadena-graph/lib/node_modules/@kadena/graph/"
    for dir in db devnet utils services; do ln -s ../src/$dir "$GRAPH/node_modules/@$dir"; done

    ( cd "$GRAPH" &&
      esbuild dist/index.d.ts --bundle --outfile=$out/bin/kadena-graph --format=cjs --platform=node
    )

    remove-references-to -t ${kadena-graph} $out/bin/kadena-graph

    substituteInPlace $out/bin/kadena-graph \
      --replace "/usr/bin/env node" ${pkgs.nodejs-slim}/bin/node

    wrapProgram $out/bin/kadena-graph \
      --set PRISMA_QUERY_ENGINE_LIBRARY "${prisma-slim}/lib/libquery_engine.node" \

    MIGRATIONS=lib/node_modules/@kadena/graph/cwd-extra-migrations
    mkdir -p $out/$MIGRATIONS
    cp -r ${kadena-graph}/$MIGRATIONS/* $out/$MIGRATIONS
  '';
in {
  inherit nodePackages kadena-graph kadena-graph-bundle;
}
