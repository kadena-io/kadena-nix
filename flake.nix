{
  description = "A nixpkgs analogue for Kadena's packages";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = inputs: inputs.flake-utils.lib.eachDefaultSystem (system:
    let pkgs = inputs.nixpkgs.legacyPackages.${system};
        graph = import pkgs/graph {
          inherit pkgs system;
        };
    in {
      packages = {
        kadena-graph = graph.kadena-graph;
      };
      apps = {
        update-graph = {
          type = "app";
          program = (pkgs.writeShellScript "update-graph" ''
            cd pkgs/graph
            ${graph.update}
          '').outPath;
        };
      };
    });
}