# coil-deflate

Userland RFC 1951 DEFLATE for [coil](https://github.com/ardax-corp/coil-lang). Package name is `deflate`, so `use deflate::{compress, decompress, Deflate, DeflateError}` resolves here.

This repo is **private**. There is no native library and no `[ffi] allow`. Raw DEFLATE blocks only (no gzip member, no zlib wrapper).

## API

```coil
use deflate::{compress, decompress, DeflateError};

let raw = compress(to_bytes("hello"))?;
let out = decompress(raw)?;
```

`compress` is LZ77 + fixed Huffman (not stored-only). `decompress` inflates stored, fixed Huffman, and dynamic Huffman blocks. Bad input returns `DeflateError`, not a panic.

| Function | Role |
|----------|------|
| `compress` | RFC 1951 deflate (`Vec<byte>` → `Vec<byte>`) |
| `decompress` | RFC 1951 inflate |
| `Deflate::compress` / `Deflate::decompress` | Same, as methods |

## Layout

| Path | Role |
|------|------|
| `src/deflate.hy` | `Deflate`, `DeflateError`, compress/inflate |
| `coil.toml` | spool manifest (`[package] name = "deflate"`); coil does not read it |

## Consume

```bash
spool add deflate --git https://github.com/ardax-corp/coil-deflate.git --rev <commit SHA>
```

No tags yet, so pin a commit. Without spool, pass `--root ../coil-deflate/src` to `coil`. See [docs/consume.md](docs/consume.md).

## License

MIT. See [LICENSE](LICENSE).
