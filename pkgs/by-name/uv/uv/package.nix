{ lib
, cmake
, darwin
, fetchFromGitHub
, installShellFiles
, libiconv
, openssl
, pkg-config
, python3Packages
, rustPlatform
, stdenv
, nix-update-script
}:

python3Packages.buildPythonApplication rec {
  pname = "uv";
  version = "0.2.3";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "astral-sh";
    repo = "uv";
    rev = version;
    hash = "sha256-NwIjuOsf6tv+kVEXA2GvQkVwDznZs5fnnkzcnVoOGpY=";
  };

  cargoDeps = rustPlatform.importCargoLock {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "async_zip-0.0.17" = "sha256-Q5fMDJrQtob54CTII3+SXHeozy5S5s3iLOzntevdGOs=";
      "pubgrub-0.2.1" = "sha256-mAPyo2R996ymzCt6TAX2G7xU1C3vDGjYF0z7R8lI1yg=";
    };
  };

  nativeBuildInputs = [
    cmake
    installShellFiles
    pkg-config
    rustPlatform.cargoSetupHook
    rustPlatform.maturinBuildHook
  ];

  buildInputs = [
    libiconv
    openssl
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.SystemConfiguration
  ];

  dontUseCmakeConfigure = true;

  cargoBuildFlags = [ "--package" "uv" ];

  # Tests require network access
  doCheck = false;

  env = {
    OPENSSL_NO_VENDOR = true;
  };

  postInstall = ''
    export HOME=$TMPDIR
    installShellCompletion --cmd uv \
      --bash <($out/bin/uv --generate-shell-completion bash) \
      --fish <($out/bin/uv --generate-shell-completion fish) \
      --zsh <($out/bin/uv --generate-shell-completion zsh)
  '';

  pythonImportsCheck = [
    "uv"
  ];

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "An extremely fast Python package installer and resolver, written in Rust";
    homepage = "https://github.com/astral-sh/uv";
    changelog = "https://github.com/astral-sh/uv/blob/${src.rev}/CHANGELOG.md";
    license = with licenses; [ asl20 mit ];
    maintainers = with maintainers; [ GaetanLepage ];
    mainProgram = "uv";
  };
}
