{
  lib,
  rustPlatform,
  fetchFromGitHub,
  fetchpatch,
  pkg-config,
  protobuf,
  bzip2,
  openssl,
  sqlite,
  zstd,
  stdenv,
  darwin,
  nix-update-script,
  nixosTests,
  rocksdb_8_11,
  callPackage,
}:

let
  # Stalwart depends on rocksdb crate:
  # https://github.com/stalwartlabs/mail-server/blob/v0.8.0/crates/store/Cargo.toml#L10
  # which expects a specific rocksdb versions:
  # https://github.com/rust-rocksdb/rust-rocksdb/blob/v0.22.0/librocksdb-sys/Cargo.toml#L3
  # See upstream issue for rocksdb 9.X support
  # https://github.com/stalwartlabs/mail-server/issues/407
  rocksdb = rocksdb_8_11;
  version = "0.8.5";
in
rustPlatform.buildRustPackage {
  pname = "stalwart-mail";
  inherit version;

  src = fetchFromGitHub {
    owner = "stalwartlabs";
    repo = "mail-server";
    rev = "v${version}";
    hash = "sha256-Y28o4BIoGcakEY3ig4wNR0sI6YBoR6BQUhXWK7fA3qo=";
    fetchSubmodules = true;
  };

  cargoHash = "sha256-axLg7igmupGHU6xohDN+UIwaZB+vt02p9WIK+P9YkY8=";

  patches = [
    # Remove "PermissionsStartOnly" from systemd service files,
    # which is deprecated and conflicts with our module's ExecPreStart.
    # Upstream PR: https://github.com/stalwartlabs/mail-server/pull/528
    (fetchpatch {
      url = "https://github.com/stalwartlabs/mail-server/pull/528/commits/6e292b3d7994441e58e367b87967c9a277bce490.patch";
      hash = "sha256-j/Li4bYNE7IppxG3FGfljra70/rHyhRvDgOkZOlhMHY=";
    })
  ];

  nativeBuildInputs = [
    pkg-config
    protobuf
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    bzip2
    openssl
    sqlite
    zstd
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.CoreFoundation
    darwin.apple_sdk.frameworks.Security
    darwin.apple_sdk.frameworks.SystemConfiguration
  ];

  env = {
    OPENSSL_NO_VENDOR = true;
    ZSTD_SYS_USE_PKG_CONFIG = true;
    ROCKSDB_INCLUDE_DIR = "${rocksdb}/include";
    ROCKSDB_LIB_DIR = "${rocksdb}/lib";
  };

  postInstall = ''
    mkdir -p $out/etc/stalwart
    cp resources/config/spamfilter.toml $out/etc/stalwart/spamfilter.toml
    cp -r resources/config/spamfilter $out/etc/stalwart/

    mkdir -p $out/lib/systemd/system

    substitute resources/systemd/stalwart-mail.service $out/lib/systemd/system/stalwart-mail.service \
      --replace "__PATH__" "$out"
  '';

  checkFlags = [
    # Require running mysql, postgresql daemon
    "--skip=directory::imap::imap_directory"
    "--skip=directory::internal::internal_directory"
    "--skip=directory::ldap::ldap_directory"
    "--skip=directory::sql::sql_directory"
    "--skip=store::blob::blob_tests"
    "--skip=store::lookup::lookup_tests"
    # thread 'directory::smtp::lmtp_directory' panicked at tests/src/store/mod.rs:122:44:
    # called `Result::unwrap()` on an `Err` value: Os { code: 2, kind: NotFound, message: "No such file or directory" }
    "--skip=directory::smtp::lmtp_directory"
    # thread 'imap::imap_tests' panicked at tests/src/imap/mod.rs:436:14:
    # Missing store type. Try running `STORE=<store_type> cargo test`: NotPresent
    "--skip=imap::imap_tests"
    # thread 'jmap::jmap_tests' panicked at tests/src/jmap/mod.rs:303:14:
    # Missing store type. Try running `STORE=<store_type> cargo test`: NotPresent
    "--skip=jmap::jmap_tests"
    # Failed to read system DNS config: io error: No such file or directory (os error 2)
    "--skip=smtp::inbound::data::data"
    # Expected "X-My-Header: true" but got Received: from foobar.net (unknown [10.0.0.123])
    "--skip=smtp::inbound::scripts::sieve_scripts"
    # panicked at tests/src/smtp/outbound/smtp.rs:173:5:
    "--skip=smtp::outbound::smtp::smtp_delivery"
    # thread 'smtp::queue::retry::queue_retry' panicked at tests/src/smtp/queue/retry.rs:119:5:
    # assertion `left == right` failed
    #   left: [1, 2, 2]
    #  right: [1, 2, 3]
    "--skip=smtp::queue::retry::queue_retry"
    # Missing store type. Try running `STORE=<store_type> cargo test`: NotPresent
    "--skip=store::store_tests"
    # thread 'config::parser::tests::toml_parse' panicked at crates/utils/src/config/parser.rs:463:58:
    # called `Result::unwrap()` on an `Err` value: "Expected ['\\n'] but found '!' in value at line 70."
    "--skip=config::parser::tests::toml_parse"
    # error[E0432]: unresolved import `r2d2_sqlite`
    # use of undeclared crate or module `r2d2_sqlite`
    "--skip=backend::sqlite::pool::SqliteConnectionManager::with_init"
  ];

  passthru = {
    update-script = nix-update-script { };
    tests.stalwart-mail = nixosTests.stalwart-mail;
  };

  meta = with lib; {
    description = "Secure & Modern All-in-One Mail Server (IMAP, JMAP, SMTP)";
    homepage = "https://github.com/stalwartlabs/mail-server";
    changelog = "https://github.com/stalwartlabs/mail-server/blob/${version}/CHANGELOG";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ happysalada onny ];
  };
}
