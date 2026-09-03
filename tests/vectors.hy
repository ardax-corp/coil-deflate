// Known raw DEFLATE vectors (not gzip members) and error cases.
use string::{to_bytes};
use deflate::{compress, decompress, DeflateError};

fn is_invalid(Result<Vec<byte>, DeflateError> r) -> bool {
    return match r {
        Result::Ok(_) => false,
        Result::Err(e) => match e {
            DeflateError::Invalid { message } => message != "",
            default => false,
        },
    };
}

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

test("zlib raw empty") {
    let raw: Vec<byte> = Vec::new();
    raw.push(3 as byte);
    raw.push(0 as byte);
    let (ok, out) = take_ok(decompress(raw));
    assert(ok, "inflate")?;
    assert(len(out) == 0, "empty")?;
}

test("stored empty") {
    let raw: Vec<byte> = Vec::new();
    raw.push(1 as byte);
    raw.push(0 as byte);
    raw.push(0 as byte);
    raw.push(255 as byte);
    raw.push(255 as byte);
    let (ok, out) = take_ok(decompress(raw));
    assert(ok, "inflate")?;
    assert(len(out) == 0, "stored empty")?;
}

test("zlib raw hello") {
    let raw: Vec<byte> = Vec::new();
    raw.push(203 as byte);
    raw.push(72 as byte);
    raw.push(205 as byte);
    raw.push(201 as byte);
    raw.push(201 as byte);
    raw.push(7 as byte);
    raw.push(0 as byte);
    let (ok, out) = take_ok(decompress(raw));
    assert(ok, "inflate")?;
    assert(eq_bytes(out, to_bytes("hello")), "hello")?;
}

test("zlib raw ten a") {
    let raw: Vec<byte> = Vec::new();
    raw.push(75 as byte);
    raw.push(76 as byte);
    raw.push(132 as byte);
    raw.push(1 as byte);
    raw.push(0 as byte);
    let want: Vec<byte> = Vec::new();
    let i: int = 0;
    while i < 10 {
        want.push("a" as byte);
        i = i + 1;
    }
    let (ok, out) = take_ok(decompress(raw));
    assert(ok, "inflate")?;
    assert(eq_bytes(out, want), "a10")?;
}

test("stored hello") {
    let raw: Vec<byte> = Vec::new();
    raw.push(1 as byte);
    raw.push(5 as byte);
    raw.push(0 as byte);
    raw.push(250 as byte);
    raw.push(255 as byte);
    let hello = to_bytes("hello");
    let i: int = 0;
    while i < len(hello) {
        raw.push(hello[i]);
        i = i + 1;
    }
    let (ok, out) = take_ok(decompress(raw));
    assert(ok, "inflate")?;
    assert(eq_bytes(out, hello), "stored hello")?;
}

test("dynamic huffman zlib raw") {
    let raw: Vec<byte> = Vec::new();
    raw.push(5 as byte);
    raw.push(193 as byte);
    raw.push(135 as byte);
    raw.push(13 as byte);
    raw.push(0 as byte);
    raw.push(48 as byte);
    raw.push(12 as byte);
    raw.push(195 as byte);
    raw.push(176 as byte);
    raw.push(120 as byte);
    raw.push(20 as byte);
    raw.push(134 as byte);
    raw.push(254 as byte);
    raw.push(127 as byte);
    raw.push(184 as byte);
    raw.push(228 as byte);
    raw.push(233 as byte);
    raw.push(134 as byte);
    raw.push(172 as byte);
    raw.push(225 as byte);
    raw.push(120 as byte);
    raw.push(164 as byte);
    raw.push(25 as byte);
    raw.push(125 as byte);
    raw.push(29 as byte);
    raw.push(31 as byte);
    let want: Vec<byte> = Vec::new();
    let n: int = 0;
    while n < 5 {
        want.push(n as byte);
        let n1 = n + 1;
        want.push(n1 as byte);
        want.push(n as byte);
        want.push(7 as byte);
        want.push(9 as byte);
        n = n + 1;
    }
    let (ok, out) = take_ok(decompress(raw));
    assert(ok, "inflate")?;
    assert(eq_bytes(out, want), "dynamic")?;
}

test("empty input is invalid") {
    let empty: Vec<byte> = Vec::new();
    assert(is_invalid(decompress(empty)), "empty")?;
}

test("reserved block type is invalid") {
    let raw: Vec<byte> = Vec::new();
    raw.push(7 as byte);
    assert(is_invalid(decompress(raw)), "btype 3")?;
}

test("bad stored nlen is invalid") {
    let raw: Vec<byte> = Vec::new();
    raw.push(1 as byte);
    raw.push(0 as byte);
    raw.push(0 as byte);
    raw.push(0 as byte);
    raw.push(0 as byte);
    assert(is_invalid(decompress(raw)), "nlen")?;
}

test("truncated stream is invalid") {
    let raw: Vec<byte> = Vec::new();
    raw.push(3 as byte);
    assert(is_invalid(decompress(raw)), "trunc")?;
}

test("our compress inflates zlib empty shape") {
    let src: Vec<byte> = Vec::new();
    let (ok, raw) = take_ok(compress(src));
    assert(ok, "compress")?;
    assert(len(raw) >= 2, "bytes")?;
    let (dok, out) = take_ok(decompress(raw));
    assert(dok, "decompress")?;
    assert(eq_bytes(out, src), "empty")?;
}
