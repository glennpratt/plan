{
  description = "plan: views and safe Jira sync for a personal beads planning workspace";

  inputs = {
    # The beads fork with Jira Server/DC support (mTLS, hierarchy, safe push).
    beads.url = "github:glennpratt/beads/jira-mtls";
    nixpkgs.follows = "beads/nixpkgs";
  };

  outputs = { self, nixpkgs, beads }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (system: pkgs:
        let
          bd = beads.packages.${system}.default;
          plan = pkgs.stdenvNoCC.mkDerivation {
            pname = "plan";
            version = "0.1.0";
            src = ./.;
            nativeBuildInputs = [ pkgs.makeWrapper ];
            buildInputs = [ pkgs.python3 ];
            dontBuild = true;
            installPhase = ''
              install -Dm755 bin/plan $out/bin/plan
              install -Dm755 bin/agent-test $out/bin/plan-agent-test
              install -Dm755 bin/agent-test-suite $out/bin/plan-agent-test-suite
              mkdir -p $out/share/plan
              cp -r skills $out/share/plan/skills
            '';
            # bd last on PATH, so a dev build of the fork earlier on PATH wins.
            postFixup = ''
              wrapProgram $out/bin/plan --suffix PATH : ${pkgs.lib.makeBinPath [ bd ]}
            '';
          };
        in
        {
          inherit plan;
          # plan plus bd itself, for a home profile.
          default = pkgs.symlinkJoin { name = "plan-with-bd"; paths = [ plan bd ]; };
        });

      devShells = forAllSystems (system: pkgs: {
        default = pkgs.mkShell {
          packages = [ beads.packages.${system}.default pkgs.python3 pkgs.jq pkgs.shellcheck ];
        };
      });
    };
}
