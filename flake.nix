{
  description = "A nixpkgs analogue for Kadena's packages";
  inputs = {
    # We currently need nixpkgs-23-05 for a working version of rollup
    # we can avoid this input when this issue is fixed:
    # https://github.com/NixOS/nixpkgs/issues/294183
    nixpkgs-23-05.url = "github:NixOS/nixpkgs/23.05";
    nixpkgs.url = "github:NixOS/nixpkgs/23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = inputs: inputs.flake-utils.lib.eachDefaultSystem (system:
    let inherit (inputs) self;
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        pkgs-23-05 = inputs.nixpkgs-23-05.legacyPackages.${system};
        nodejs-slim = pkgs.nodejs-slim_20;
        nodePackages = import "${self}/pkgs/nodePackages" {
          inherit pkgs system;
          nodejs = pkgs.nodejs_20;
        };
        graph = import pkgs/graph {
          inherit pkgs system nodePackages nodejs-slim;
        };
        kadena-cli = import pkgs/kadena-cli {
          inherit pkgs system nodePackages nodejs-slim;
          rollup = pkgs-23-05.nodePackages.rollup;
        };
    in {
      packages = {
        inherit (graph) kadena-graph kadena-graph-unbundled;
        clibundle = nodePackages."clibundle-../kadena-cli";
        kadena-cli = kadena-cli.kadena-cli-bundled;
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