{ pkgs ? import <nixpkgs> {inherit system;}
, system ? builtins.currentSystem
, nodePackages ? import ../nodePackages { inherit pkgs system; }
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
in {
  inherit nodePackages kadena-graph;
}
