# coil-deflate

Userland RFC 1951 DEFLATE for [coil](https://github.com/ardax-corp/coil-lang). Package name is `deflate`, so `use deflate::{compress, decompress, Deflate, DeflateError}` resolves here.

Pure Coil: no native library and no `[ffi] allow`. Raw DEFLATE blocks only (no gzip member, no zlib wrapper); for gzip see [coil-gzip](https://github.com/ardax-corp/coil-gzip).

## Example

```coil
use tests::assert;
use string::{to_bytes, from_bytes};
use deflate::{compress, decompress, DeflateError};

fn roundtrip(string text) -> Result<string, DeflateError> {
    let packed = compress(to_bytes(text))?;
    let out = decompress(packed)?;
    return from_bytes(out).ok() ?? "";
}

fn main() {
    assert!((roundtrip("hello hello hello").ok() ?? "") == "hello hello hello");
}
```

Run it with `coil --root ../coil-deflate/src --root ../coil-stdlib/src main.coil` (or `spool run`).

## API

`compress` is LZ77 + fixed Huffman (not stored-only). `decompress` inflates stored, fixed Huffman, and dynamic Huffman blocks. Both take `Vec<byte>` and return `Result<Vec<byte>, DeflateError>`. Bad input returns `DeflateError::Invalid { message }`, not a panic.

| Item | Role |
|------|------|
| `compress` | RFC 1951 deflate (`Vec<byte>` → `Vec<byte>`) |
| `decompress` | RFC 1951 inflate |
| `Deflate::compress` / `Deflate::decompress` | Same, as static methods |
| `DeflateError` | Failure type (`Invalid { message }`) |

## Layout

| Path | Role |
|------|------|
| `src/deflate.coil` | The `deflate` module: `compress` / `decompress`, `Deflate`, `DeflateError`, and the internal encoder/inflater |
| `tests/` | Round-trip, known-vector and error-case tests (`coil test`) |
| `coil.toml` | spool manifest (`[package] name = "deflate"`); coil does not read it |

## Consume

```bash
spool add deflate --git https://github.com/ardax-corp/coil-deflate.git --rev <commit SHA>
```

No tags yet, so pin a commit. Without spool, clone this repo next to your project and pass `--root ../coil-deflate/src` to `coil`. See [docs/consume.md](docs/consume.md).

## License

MIT. See [LICENSE](LICENSE).
