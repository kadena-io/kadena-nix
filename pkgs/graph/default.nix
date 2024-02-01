# This file has been generated by node2nix 1.11.1. Do not edit!

{ pkgs ? import <nixpkgs> {inherit system;}
, system ? builtins.currentSystem
, nodejs ? pkgs.nodejs}:
let
  nodeEnv = import ./node-env.nix {
    inherit (pkgs) stdenv lib python2 runCommand writeTextFile writeShellScript;
    inherit pkgs nodejs;
    libtool = if pkgs.stdenv.isDarwin then pkgs.darwin.cctools else null;
  };
  nodePackages = import ./node-packages.nix {
    inherit (pkgs) fetchurl nix-gitignore stdenv lib fetchgit;
    inherit nodeEnv;
  };
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
  update = pkgs.writeShellScript "update-graph" ''
    ${pkgs.node2nix}/bin/node2nix -i node-packages.json
  '';
in {
  inherit nodePackages kadena-graph update;
}
