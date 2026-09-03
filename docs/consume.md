# Consuming coil-deflate

This package is `deflate`. `use deflate::{compress, decompress, Deflate, DeflateError}` resolves from `src/deflate.hy`. This repo is **private** (`https://github.com/ardax-corp/coil-deflate.git`); clone with credentials that can read it. There is no native/FFI dep.

Coil-to-Coil deps will be spool-owned once a public `spool` CLI exists. Until then `{ git }` parses and the pin is `coil.lock` `rev` + `content_hash`.

## Sibling checkout

Clone this repo next to your project. In the consumer `coil.toml`:

```toml
[module]
roots = ["./src", "../coil-deflate/src"]
```

`roots` is what loads `src/deflate.hy`. The compiler does not follow path deps for discovery.

## Git dep and coil.lock

`{ git }` is the parseable form. `version` is optional schema, not a tag. `rev` on the dep is stored only. Do not run `spool add`. There is no public spool CLI.

```toml
[dependencies]
deflate = { git = "https://github.com/ardax-corp/coil-deflate.git" }

[module]
roots = ["./src", "./.spool/deps/deflate/src"]
```

This repo has no tags. The pin is `coil.lock` `rev` + `content_hash`. Omit `tag`. Use sibling checkout until spool materializes `.spool/deps`. The compiler does not read `coil.lock` and does not inject roots.

```
# spool lockfile v1
[[package]]
name = 'deflate'
git = 'https://github.com/ardax-corp/coil-deflate.git'
rev = '<commit SHA>'
content_hash = '<tree SHA>'
```

`rev` is the commit. `content_hash` is that commit's git tree (`git rev-parse 'HEAD^{tree}'`). Replace both when you move the pin.

## Call compress / decompress

Signatures are in [`src/deflate.hy`](../src/deflate.hy). Call patterns are in [`tests/roundtrip.hy`](../tests/roundtrip.hy) and [`tests/vectors.hy`](../tests/vectors.hy).

```coil
use string::{to_bytes};
use deflate::{compress, decompress, Deflate, DeflateError};

let raw = compress(to_bytes("hello"))?;
let out = decompress(raw)?;
let also = Deflate::decompress(raw)?;
```

`compress` / `decompress` take `Vec<byte>` and return `Result<Vec<byte>, DeflateError>`. Streams are raw DEFLATE (RFC 1951), not gzip members.

### DeflateError

```coil
enum DeflateError {
    Invalid { message: string },
}
```

Malformed input returns `DeflateError::Invalid`, not a panic.

```coil
match decompress(Vec::new()) {
    Result::Ok(_) => false,
    Result::Err(e) => match e {
        DeflateError::Invalid { message } => message != "",
        default => false,
    },
}
```
