# Consuming coil-deflate

This package is `deflate`. `use deflate::{compress, decompress, Deflate, DeflateError}` resolves from `src/deflate.coil`. The repo is `https://github.com/ardax-corp/coil-deflate.git`. There is no native/FFI dep.

## Depend on it

With [spool](https://github.com/ardax-corp/spool):

```bash
spool add deflate --git https://github.com/ardax-corp/coil-deflate.git --rev <commit SHA>
```

This repo has no tags, so pin a commit with `--rev`. spool records the dep in `coil.toml`, writes `coil.lock` (`rev` + `content_hash`), links `.spool/deps/deflate`, and passes `--root` for it and coil-stdlib to `coil` on `spool build` / `run` / `test`.

Without spool, clone this repo next to your project and pass the roots yourself. coil reads no `coil.toml` and no `coil.lock`.

```bash
git clone https://github.com/ardax-corp/coil-deflate.git ../coil-deflate
coil --root ../coil-deflate/src --root ../coil-stdlib/src main.coil
```

## Call compress / decompress

Signatures are in [`src/deflate.coil`](../src/deflate.coil). Call patterns are in [`tests/roundtrip.coil`](../tests/roundtrip.coil) and [`tests/vectors.coil`](../tests/vectors.coil).

```coil
use string::{to_bytes};
use deflate::{compress, decompress, Deflate, DeflateError};

fn pack_and_unpack() -> Result<Vec<byte>, DeflateError> {
    let raw = compress(to_bytes("hello"))?;
    let out = decompress(raw)?;
    let also = Deflate::decompress(raw)?;
    return out;
}
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
