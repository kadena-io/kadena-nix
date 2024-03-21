{
  description = "A nixpkgs analogue for Kadena's packages";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = inputs: inputs.flake-utils.lib.eachDefaultSystem (system:
    let inherit (inputs) self;
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        nodePackages = import "${self}/pkgs/nodePackages" {
          inherit pkgs system;
          nodejs = pkgs.nodejs;
        };
        graph = import pkgs/graph {
          inherit pkgs system nodePackages;
        };
        kadena-client = import pkgs/kadena-client {
          inherit pkgs system nodePackages;
        };
    in {
      packages = {
        kadena-graph = graph.kadena-graph;
        inherit (kadena-client) kadena-client kadena-client-bundle;
      };
      apps = {
        update-node-packages = {
          type = "app";
          program = (pkgs.writeShellScript "update-node-packages" ''
            cd pkgs/nodePackages
            ${nodePackages.update}
          '').outPath;
        };
      };
    });
}