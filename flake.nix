{
  description = "plan: views and safe Jira sync for a personal beads planning workspace";

  inputs = {
    # The beads fork with Jira Server/DC support (mTLS, hierarchy, safe push).
    beads.url = "github:glennpratt/beads/jira-mtls-rebase";
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
          # The dolt CLI for server mode (bd serve). bd needs 2.6.0 or newer
          # there; nixpkgs lags, so this is upstream's release binary, at the
          # version and digests beads pins (tools/bazel/dolt.bzl).
          dolt =
            let
              version = "2.6.0";
              release = {
                aarch64-darwin = { asset = "darwin-arm64"; sha256 = "018d14904b5a644b3fa88ca2c6b5b940756cace592c69b05a8587a94587e17dd"; };
                x86_64-darwin = { asset = "darwin-amd64"; sha256 = "f20ed1ec96d06d627f601176e80cf630140a063ede0ebf125c28cf0ed4e789a2"; };
                x86_64-linux = { asset = "linux-amd64"; sha256 = "a8d4c2e2e94b85fd3592cb80748044f846ccfd03d25a536ed1f754baf7da6401"; };
                aarch64-linux = { asset = "linux-arm64"; sha256 = "6ca5cba6af38e6b52acd66fa23471e392f054f6bd15c0004498c491b9ba6ecde"; };
              }.${system};
            in
            pkgs.stdenvNoCC.mkDerivation {
              pname = "dolt";
              inherit version;
              src = pkgs.fetchurl {
                url = "https://github.com/dolthub/dolt/releases/download/v${version}/dolt-${release.asset}.tar.gz";
                inherit (release) sha256;
              };
              nativeBuildInputs = pkgs.lib.optional pkgs.stdenv.isLinux pkgs.autoPatchelfHook;
              installPhase = "install -Dm755 bin/dolt $out/bin/dolt";
            };
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
            # bd and dolt last on PATH, so a dev build of the fork earlier on
            # PATH wins; dolt there lets `plan serve` start under a service
            # manager's minimal PATH.
            postFixup = ''
              wrapProgram $out/bin/plan --suffix PATH : ${pkgs.lib.makeBinPath [ bd dolt ]}
            '';
          };
        in
        {
          inherit plan dolt;
          # plan plus bd and dolt themselves, for a home profile.
          default = pkgs.symlinkJoin { name = "plan-with-bd"; paths = [ plan bd dolt ]; };
        });

      devShells = forAllSystems (system: pkgs: {
        default = pkgs.mkShell {
          packages = [ beads.packages.${system}.default pkgs.python3 pkgs.jq pkgs.shellcheck ];
        };
      });
    };
}
