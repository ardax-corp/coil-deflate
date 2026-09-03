// Round-trip compress/decompress and encoder shape (LZ77 + Huffman, not stored-only).
use string::{to_bytes};
use deflate::{compress, decompress, Deflate, DeflateError};

fn eq_bytes(Vec<byte> a, Vec<byte> b) -> bool {
    if len(a) != len(b) {
        return false;
    }
    let i = 0;
    while i < len(a) {
        if a[i] != b[i] {
            return false;
        }
        i = i + 1;
    }
    return true;
}

fn take_ok(Result<Vec<byte>, DeflateError> r) -> (bool, Vec<byte>) {
    return match r {
        Result::Ok(v) => (true, v),
        Result::Err(_) => {
            let empty: Vec<byte> = Vec::new();
            (false, empty)
        },
    };
}

fn roundtrip(Vec<byte> src) -> bool {
    let (cok, raw) = take_ok(compress(src));
    if !cok {
        return false;
    }
    let (dok, out) = take_ok(decompress(raw));
    if !dok {
        return false;
    }
    if !eq_bytes(src, out) {
        return false;
    }
    let (cok2, also) = take_ok(Deflate::compress(src));
    if !cok2 {
        return false;
    }
    let (dok2, out2) = take_ok(Deflate::decompress(also));
    if !dok2 {
        return false;
    }
    return eq_bytes(src, out2);
}

fn repeat_byte(byte c, int n) -> Vec<byte> {
    let out: Vec<byte> = Vec::new();
    let i = 0;
    while i < n {
        out.push(c);
        i = i + 1;
    }
    return out;
}

test("empty roundtrip") {
    let src: Vec<byte> = Vec::new();
    assert(roundtrip(src), "empty")?;
}

test("hello roundtrip") {
    assert(roundtrip(to_bytes("hello")), "hello")?;
}

test("repeated bytes are compressed") {
    let src = repeat_byte("a" as byte, 100);
    let (ok, raw) = take_ok(compress(src));
    assert(ok, "compress")?;
    assert(len(raw) < 50, "lz77 shrinks repeats")?;
    let (dok, out) = take_ok(decompress(raw));
    assert(dok, "decompress")?;
    assert(eq_bytes(src, out), "repeat roundtrip")?;
}

test("mixed text roundtrip") {
    assert(roundtrip(to_bytes("The quick brown fox jumps over the lazy dog")), "pangram")?;
}

test("binary-ish sequence roundtrip") {
    let src: Vec<byte> = Vec::new();
    let i: int = 0;
    while i < 64 {
        src.push(i as byte);
        let tri = i * 3;
        src.push(tri as byte);
        i = i + 1;
    }
    assert(roundtrip(src), "seq")?;
}

test("compress is not stored-only") {
    let src = repeat_byte("x" as byte, 80);
    let (ok, raw) = take_ok(compress(src));
    assert(ok, "compress")?;
    assert(len(raw) > 0, "nonempty")?;
    let hdr = raw[0] as int;
    let btype = (hdr >> 1) & 3;
    assert(btype == 1, "fixed huffman block")?;
}
