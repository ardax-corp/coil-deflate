// Package root (`deflate`). RFC 1951 raw DEFLATE in pure Coil: no zlib or gzip
// wrapper, no native library. `compress` / `decompress` are the entry points;
// `Deflate` carries the same pair as static methods and `DeflateError` is the
// failure type. Encoder: LZ77 + fixed Huffman. Inflater: stored, fixed, and
// dynamic Huffman blocks. Everything below the error type down to `Deflate`
// (bit I/O, Huffman tables, LZ77 matching) is internal.

/// Why `compress` or `decompress` failed.
///
/// Bad input is reported through this error, never a panic. There is one
/// variant today; match it with a `default` arm so a later variant does not
/// break your code.
///
/// # Examples
///
/// ```
/// use deflate::{decompress, DeflateError};
/// # use tests::assert;
/// // 0b111: final block with the reserved block type 3.
/// let bad: Vec<byte> = Vec::new();
/// bad.push(7 as byte);
/// let reason = match decompress(bad) {
///     Result::Ok(_) => "",
///     Result::Err(e) => match e {
///         DeflateError::Invalid { message } => message,
///         default => "other",
///     },
/// };
/// assert!(reason == "reserved block type");
/// ```
enum DeflateError {
    /// The input is not a valid DEFLATE stream. `message` is a short reason,
    /// such as `"empty input"`, `"truncated"` or `"bad huffman symbol"`.
    Invalid { message: string },
}

fn invalid(string message) -> DeflateError {
    return DeflateError::Invalid { message: message };
}

fn zeros_int(int n) -> Vec<int> {
    let v: Vec<int> = Vec::new();
    let i = 0;
    while i < n {
        v.push(0);
        i = i + 1;
    }
    return v;
}

fn filled_int(int n, int x) -> Vec<int> {
    let v: Vec<int> = Vec::new();
    let i = 0;
    while i < n {
        v.push(x);
        i = i + 1;
    }
    return v;
}

fn length_extra(int i) -> int {
    if i < 8 {
        return 0;
    }
    if i == 28 {
        return 0;
    }
    return (i - 8) / 4 + 1;
}

fn length_base(int i) -> int {
    if i < 8 {
        return 3 + i;
    }
    if i == 28 {
        return 258;
    }
    let extra = (i - 8) / 4 + 1;
    let slot = (i - 8) % 4;
    let start = 11;
    let e = 1;
    while e < extra {
        start = start + 4 * (1 << e);
        e = e + 1;
    }
    return start + slot * (1 << extra);
}

fn dist_extra(int i) -> int {
    if i < 4 {
        return 0;
    }
    return (i - 2) / 2;
}

fn dist_base(int i) -> int {
    if i < 4 {
        return i + 1;
    }
    let extra = (i - 2) / 2;
    let slot = (i - 2) % 2;
    let start = 5;
    let e = 1;
    while e < extra {
        start = start + 2 * (1 << e);
        e = e + 1;
    }
    return start + slot * (1 << extra);
}

fn encode_length(int length) -> (int, int, int) {
    let i = 0;
    while i < 29 {
        let b = length_base(i);
        let e = length_extra(i);
        let span = 1 << e;
        if length >= b {
            if length < b + span {
                return (257 + i, e, length - b);
            }
        }
        i = i + 1;
    }
    return (285, 0, 0);
}

fn encode_dist(int dist) -> (int, int, int) {
    let i = 0;
    while i < 30 {
        let b = dist_base(i);
        let e = dist_extra(i);
        let span = 1 << e;
        if dist >= b {
            if dist < b + span {
                return (i, e, dist - b);
            }
        }
        i = i + 1;
    }
    return (29, 13, dist - 24577);
}

fn fixed_litlen(int sym) -> (int, int) {
    if sym <= 143 {
        return (48 + sym, 8);
    }
    if sym <= 255 {
        return (400 + (sym - 144), 9);
    }
    if sym <= 279 {
        return (sym - 256, 7);
    }
    return (192 + (sym - 280), 8);
}

fn clen_order() -> Vec<int> {
    let o: Vec<int> = Vec::new();
    o.push(16);
    o.push(17);
    o.push(18);
    o.push(0);
    o.push(8);
    o.push(7);
    o.push(9);
    o.push(6);
    o.push(10);
    o.push(5);
    o.push(11);
    o.push(4);
    o.push(12);
    o.push(3);
    o.push(13);
    o.push(2);
    o.push(14);
    o.push(1);
    o.push(15);
    return o;
}

fn fixed_ll_lengths() -> Vec<int> {
    let v: Vec<int> = Vec::new();
    let i = 0;
    while i < 288 {
        if i <= 143 {
            v.push(8);
        } else {
            if i <= 255 {
                v.push(9);
            } else {
                if i <= 279 {
                    v.push(7);
                } else {
                    v.push(8);
                }
            }
        }
        i = i + 1;
    }
    return v;
}

fn fixed_dist_lengths() -> Vec<int> {
    return filled_int(32, 5);
}

class BitWriter {
    pub out: Vec<byte>,
    acc: int,
    nbits: int,
}

class BitReader {
    pub bytes: Vec<byte>,
    pub pos: int,
    acc: int,
    nbits: int,
}

class Huff {
    counts: Vec<int>,
    first: Vec<int>,
    offs: Vec<int>,
    symbols: Vec<int>,
    maxbits: int,
}

impl BitWriter {
    pub static fn new() -> BitWriter {
        let out: Vec<byte> = Vec::new();
        return new BitWriter(out, 0, 0);
    }

    pub fn write_bits(int val, int n) {
        let v = val;
        let left = n;
        while left > 0 {
            self.acc = self.acc | ((v & 1) << self.nbits);
            self.nbits = self.nbits + 1;
            v = v >> 1;
            left = left - 1;
            if self.nbits == 8 {
                self.out.push(self.acc as byte);
                self.acc = 0;
                self.nbits = 0;
            }
        }
    }

    pub fn write_huff(int code, int nbits) {
        let i = nbits - 1;
        while i >= 0 {
            self.write_bits((code >> i) & 1, 1);
            i = i - 1;
        }
    }

    pub fn emit_literal(int c) {
        let (code, n) = fixed_litlen(c);
        self.write_huff(code, n);
    }

    pub fn emit_eob() {
        let (code, n) = fixed_litlen(256);
        self.write_huff(code, n);
    }

    pub fn emit_match(int length, int dist) {
        let (lc, en, ev) = encode_length(length);
        let (code, n) = fixed_litlen(lc);
        self.write_huff(code, n);
        if en > 0 {
            self.write_bits(ev, en);
        }
        let (dc, den, dev) = encode_dist(dist);
        self.write_huff(dc, 5);
        if den > 0 {
            self.write_bits(dev, den);
        }
    }

    pub fn finish() -> Vec<byte> {
        if self.nbits > 0 {
            self.out.push(self.acc as byte);
            self.acc = 0;
            self.nbits = 0;
        }
        return self.out;
    }
}

impl BitReader {
    pub static fn new(Vec<byte> bytes) -> BitReader {
        return new BitReader(bytes, 0, 0, 0);
    }

    pub fn get_bit() -> Result<int, DeflateError> {
        if self.nbits == 0 {
            if self.pos >= self.bytes.len() {
                raise invalid("truncated");
            }
            self.acc = self.bytes[self.pos] as int;
            self.pos = self.pos + 1;
            self.nbits = 8;
        }
        let b = self.acc & 1;
        self.acc = self.acc >> 1;
        self.nbits = self.nbits - 1;
        return b;
    }

    pub fn get_bits(int n) -> Result<int, DeflateError> {
        let v = 0;
        let i = 0;
        while i < n {
            let b = self.get_bit()?;
            v = v | (b << i);
            i = i + 1;
        }
        return v;
    }

    pub fn align() {
        self.acc = 0;
        self.nbits = 0;
    }
}

impl Huff {
    pub static fn build(Vec<int> lengths) -> Result<Huff, DeflateError> {
        let counts = zeros_int(16);
        let first = zeros_int(16);
        let offs = zeros_int(16);
        let nsym = lengths.len();
        let i = 0;
        let maxbits = 0;
        while i < nsym {
            let l = lengths[i];
            if l < 0 {
                raise invalid("bad code length");
            }
            if l > 15 {
                raise invalid("bad code length");
            }
            if l > 0 {
                counts[l] = counts[l] + 1;
                if l > maxbits {
                    maxbits = l;
                }
            }
            i = i + 1;
        }
        let left = 1;
        let ln = 1;
        while ln <= 15 {
            left = left << 1;
            left = left - counts[ln];
            if left < 0 {
                raise invalid("oversubscribed huffman");
            }
            ln = ln + 1;
        }
        let code = 0;
        ln = 1;
        while ln <= 15 {
            code = (code + counts[ln - 1]) << 1;
            first[ln] = code;
            ln = ln + 1;
        }
        let acc = 0;
        ln = 1;
        while ln <= 15 {
            offs[ln] = acc;
            acc = acc + counts[ln];
            ln = ln + 1;
        }
        let symbols = zeros_int(acc);
        let next_code = zeros_int(16);
        ln = 1;
        while ln <= 15 {
            next_code[ln] = first[ln];
            ln = ln + 1;
        }
        let sym = 0;
        while sym < nsym {
            let l = lengths[sym];
            if l > 0 {
                let c = next_code[l];
                let idx = offs[l] + (c - first[l]);
                symbols[idx] = sym;
                next_code[l] = c + 1;
            }
            sym = sym + 1;
        }
        return new Huff(counts, first, offs, symbols, maxbits);
    }

    pub fn decode(BitReader br) -> Result<int, DeflateError> {
        let code = 0;
        let ln = 1;
        while ln <= self.maxbits {
            let b = br.get_bit()?;
            code = (code << 1) | b;
            let cnt = self.counts[ln];
            if cnt > 0 {
                let first = self.first[ln];
                if code >= first {
                    if code < first + cnt {
                        return self.symbols[self.offs[ln] + (code - first)];
                    }
                }
            }
            ln = ln + 1;
        }
        raise invalid("bad huffman symbol");
    }
}

fn hash3(Vec<byte> data, int i) -> int {
    let a = data[i] as int;
    let b = data[i + 1] as int;
    let c = data[i + 2] as int;
    return ((a << 10) ^ (b << 5) ^ c) & 4095;
}

fn match_len(Vec<byte> data, int i, int p, int n) -> int {
    let ml = 0;
    let maxm = 258;
    if n - i < maxm {
        maxm = n - i;
    }
    while ml < maxm {
        if data[i + ml] != data[p + ml] {
            break;
        }
        ml = ml + 1;
    }
    return ml;
}

fn insert_hash(Vec<int> heads, Vec<int> prev, Vec<byte> data, int i, int n) {
    if i + 2 >= n {
        return;
    }
    let h = hash3(data, i);
    prev[i] = heads[h];
    heads[h] = i;
}

fn find_match(Vec<int> heads, Vec<int> prev, Vec<byte> data, int i, int n) -> (int, int) {
    if i + 2 >= n {
        return (0, 0);
    }
    let h = hash3(data, i);
    let p = heads[h];
    let best_len = 2;
    let best_dist = 0;
    let chain = 0;
    while p >= 0 {
        if chain >= 32 {
            break;
        }
        if i - p > 32768 {
            break;
        }
        if i - p >= 1 {
            let ml = match_len(data, i, p, n);
            if ml > best_len {
                best_len = ml;
                best_dist = i - p;
                if ml >= 258 {
                    break;
                }
            }
        }
        p = prev[p];
        chain = chain + 1;
    }
    if best_len >= 3 {
        return (best_dist, best_len);
    }
    return (0, 0);
}

fn copy_match(Vec<byte> out, int dist, int length) -> Result<(), DeflateError> {
    if dist <= 0 {
        raise invalid("bad distance");
    }
    if dist > out.len() {
        raise invalid("distance too far");
    }
    let k = 0;
    while k < length {
        let src = out.len() - dist;
        out.push(out[src]);
        k = k + 1;
    }
    return ();
}

fn inflate_codes(BitReader br, Huff ll, Huff dist, Vec<byte> out) -> Result<(), DeflateError> {
    while true {
        let sym = ll.decode(br)?;
        if sym < 256 {
            out.push(sym as byte);
            continue;
        }
        if sym == 256 {
            return ();
        }
        if sym > 285 {
            raise invalid("bad length symbol");
        }
        let li = sym - 257;
        let extra = length_extra(li);
        let length = length_base(li) + br.get_bits(extra)?;
        let dc = dist.decode(br)?;
        if dc > 29 {
            raise invalid("bad distance symbol");
        }
        let de = dist_extra(dc);
        let distance = dist_base(dc) + br.get_bits(de)?;
        copy_match(out, distance, length)?;
    }
}

fn read_code_lengths(BitReader br, Huff clen, int ncodes) -> Result<Vec<int>, DeflateError> {
    let lens: Vec<int> = Vec::new();
    while lens.len() < ncodes {
        let sym = clen.decode(br)?;
        if sym <= 15 {
            lens.push(sym);
            continue;
        }
        if sym == 16 {
            if lens.len() == 0 {
                raise invalid("repeat with no previous length");
            }
            let rep = 3 + br.get_bits(2)?;
            let prev = lens[lens.len() - 1];
            let k = 0;
            while k < rep {
                lens.push(prev);
                k = k + 1;
            }
            continue;
        }
        let rep = 0;
        if sym == 17 {
            rep = 3 + br.get_bits(3)?;
        } else {
            if sym == 18 {
                rep = 11 + br.get_bits(7)?;
            } else {
                raise invalid("bad code length symbol");
            }
        }
        let k = 0;
        while k < rep {
            lens.push(0);
            k = k + 1;
        }
    }
    if lens.len() != ncodes {
        raise invalid("code length overflow");
    }
    return lens;
}

fn inflate_dynamic(BitReader br, Vec<byte> out) -> Result<(), DeflateError> {
    let hlit = br.get_bits(5)? + 257;
    let hdist = br.get_bits(5)? + 1;
    let hclen = br.get_bits(4)? + 4;
    if hlit > 286 {
        raise invalid("bad hlit");
    }
    if hdist > 32 {
        raise invalid("bad hdist");
    }
    if hclen > 19 {
        raise invalid("bad hclen");
    }
    let order = clen_order();
    let clens = zeros_int(19);
    let i = 0;
    while i < hclen {
        clens[order[i]] = br.get_bits(3)?;
        i = i + 1;
    }
    let clen = Huff::build(clens)?;
    let all = read_code_lengths(br, clen, hlit + hdist)?;
    let ll_len: Vec<int> = Vec::new();
    i = 0;
    while i < hlit {
        ll_len.push(all[i]);
        i = i + 1;
    }
    let dist_len: Vec<int> = Vec::new();
    while i < hlit + hdist {
        dist_len.push(all[i]);
        i = i + 1;
    }
    let ll = Huff::build(ll_len)?;
    let dist = Huff::build(dist_len)?;
    return inflate_codes(br, ll, dist, out)?;
}

fn inflate_stored(BitReader br, Vec<byte> out) -> Result<(), DeflateError> {
    br.align();
    if br.pos + 4 > br.bytes.len() {
        raise invalid("truncated stored length");
    }
    let ln = (br.bytes[br.pos] as int) | ((br.bytes[br.pos + 1] as int) << 8);
    let nlen = (br.bytes[br.pos + 2] as int) | ((br.bytes[br.pos + 3] as int) << 8);
    if (ln ^ 65535) != nlen {
        raise invalid("bad stored nlen");
    }
    br.pos = br.pos + 4;
    if br.pos + ln > br.bytes.len() {
        raise invalid("truncated stored data");
    }
    let k = 0;
    while k < ln {
        out.push(br.bytes[br.pos]);
        br.pos = br.pos + 1;
        k = k + 1;
    }
    return ();
}

/// The RFC 1951 codec, as a namespace for `Deflate::compress` and
/// `Deflate::decompress`.
///
/// The free functions `compress` and `decompress` call these and behave the
/// same; use whichever spelling reads better. There is nothing to construct.
///
/// # Examples
///
/// ```
/// use deflate::{Deflate};
/// use string::{to_bytes};
/// # use tests::assert;
/// let src = to_bytes("abcabcabcabc");
/// let packed = Deflate::compress(src).ok() ?? Vec::new();
/// let back = Deflate::decompress(packed).ok() ?? Vec::new();
/// assert!(back == src);
/// ```
class Deflate {
    _unused: int,
}

impl Deflate {
    /// Compresses `data` into a raw DEFLATE stream (RFC 1951, no zlib or gzip
    /// wrapper).
    ///
    /// The output is one final block coded with LZ77 matches (32 KiB window,
    /// lengths 3 to 258) and the fixed Huffman tables, so repetitive input
    /// shrinks; it never falls back to stored blocks, so input with no
    /// repeats can grow slightly. Empty input gives a valid stream that
    /// decompresses to empty.
    ///
    /// # Errors
    ///
    /// The encoder does not fail today; the `Result` keeps the signature in
    /// step with `decompress`.
    ///
    /// # Examples
    ///
    /// ```
    /// use deflate::{Deflate};
    /// use string::{to_bytes};
    /// # use tests::assert;
    /// let src = to_bytes("to be or not to be, to be or not to be");
    /// let packed = Deflate::compress(src).ok() ?? Vec::new();
    /// assert!(packed.len() < src.len());
    /// ```
    pub static fn compress(Vec<byte> data) -> Result<Vec<byte>, DeflateError> {
        let n = data.len();
        let w = BitWriter::new();
        w.write_bits(3, 3);
        let heads = filled_int(4096, -1);
        let prev = filled_int(n, -1);
        let i = 0;
        while i < n {
            let (dist, mlen) = find_match(heads, prev, data, i, n);
            if mlen >= 3 {
                if i + 1 < n {
                    let (d2, l2) = find_match(heads, prev, data, i + 1, n);
                    if l2 > mlen {
                        w.emit_literal(data[i] as int);
                        insert_hash(heads, prev, data, i, n);
                        i = i + 1;
                        dist = d2;
                        mlen = l2;
                    }
                }
            }
            insert_hash(heads, prev, data, i, n);
            if mlen >= 3 {
                w.emit_match(mlen, dist);
                let k = i + 1;
                let end = i + mlen;
                while k < end {
                    insert_hash(heads, prev, data, k, n);
                    k = k + 1;
                }
                i = i + mlen;
                continue;
            }
            w.emit_literal(data[i] as int);
            i = i + 1;
        }
        w.emit_eob();
        return w.finish();
    }

    /// Decompresses a raw DEFLATE stream (RFC 1951) back to its bytes.
    ///
    /// Reads stored, fixed Huffman and dynamic Huffman blocks until the block
    /// marked final, so streams from other encoders (zlib, gzip bodies) work.
    /// Bytes after the final block are ignored.
    ///
    /// # Errors
    ///
    /// Returns `DeflateError::Invalid` for empty input, a truncated stream, the
    /// reserved block type, a bad stored-block length, malformed Huffman
    /// tables or codes, or a back-reference past the start of the output.
    ///
    /// # Examples
    ///
    /// ```
    /// use deflate::{Deflate};
    /// # use tests::assert;
    /// // A fixed-Huffman block holding just the end-of-block code.
    /// let empty: Vec<byte> = Vec::new();
    /// empty.push(3 as byte);
    /// empty.push(0 as byte);
    /// let out = Deflate::decompress(empty).ok() ?? Vec::new();
    /// assert!(out.len() == 0);
    /// assert!(Deflate::decompress(Vec::new()).is_err());
    /// ```
    pub static fn decompress(Vec<byte> data) -> Result<Vec<byte>, DeflateError> {
        if data.len() == 0 {
            raise invalid("empty input");
        }
        let br = BitReader::new(data);
        let out: Vec<byte> = Vec::new();
        let ll_fixed = Huff::build(fixed_ll_lengths())?;
        let dist_fixed = Huff::build(fixed_dist_lengths())?;
        while true {
            let bfinal = br.get_bits(1)?;
            let btype = br.get_bits(2)?;
            if btype == 0 {
                inflate_stored(br, out)?;
            } else {
                if btype == 1 {
                    inflate_codes(br, ll_fixed, dist_fixed, out)?;
                } else {
                    if btype == 2 {
                        inflate_dynamic(br, out)?;
                    } else {
                        raise invalid("reserved block type");
                    }
                }
            }
            if bfinal == 1 {
                break;
            }
        }
        return out;
    }
}

/// Compresses `data` into a raw DEFLATE stream (RFC 1951, no zlib or gzip
/// wrapper). Same as `Deflate::compress`.
///
/// Uses LZ77 matching with the fixed Huffman tables. Input with no repeats
/// can come out slightly larger than it went in.
///
/// # Errors
///
/// The encoder does not fail today; the `Result` keeps the signature in step
/// with `decompress`.
///
/// # Examples
///
/// ```
/// use deflate::{compress, decompress};
/// use string::{to_bytes, from_bytes};
/// # use tests::assert;
/// let packed = compress(to_bytes("hello hello hello hello")).ok() ?? Vec::new();
/// let back = decompress(packed).ok() ?? Vec::new();
/// assert!((from_bytes(back).ok() ?? "") == "hello hello hello hello");
/// ```
fn compress(Vec<byte> data) -> Result<Vec<byte>, DeflateError> {
    return Deflate::compress(data)?;
}

/// Decompresses a raw DEFLATE stream (RFC 1951) back to its bytes. Same as
/// `Deflate::decompress`.
///
/// Accepts stored, fixed Huffman and dynamic Huffman blocks. The input must be
/// bare DEFLATE: strip a gzip or zlib header and trailer first.
///
/// # Errors
///
/// Returns `DeflateError::Invalid` when the input is empty, truncated or
/// malformed. It never panics on bad input.
///
/// # Examples
///
/// ```
/// use deflate::{compress, decompress, DeflateError};
/// use string::{to_bytes};
/// # use tests::assert;
/// fn roundtrip(Vec<byte> data) -> Result<Vec<byte>, DeflateError> {
///     return decompress(compress(data)?)?;
/// }
///
/// fn main() {
///     let src = to_bytes("abracadabra");
///     assert!((roundtrip(src).ok() ?? Vec::new()) == src);
///     assert!(decompress(Vec::new()).is_err());
/// }
/// ```
fn decompress(Vec<byte> data) -> Result<Vec<byte>, DeflateError> {
    return Deflate::decompress(data)?;
}
