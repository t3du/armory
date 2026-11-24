
package iron.format.png;

import haxe.io.Bytes;

class Deflate {

	static var lengthBase = [
		3, 4, 5, 6, 7, 8, 9, 10,
		11, 13, 15, 17, 19, 23, 27, 31,
		35, 43, 51, 59, 67, 83, 99, 115,
		131, 163, 195, 227, 258
	];

	static var lengthExtra = [
		0, 0, 0, 0, 0, 0, 0, 0,
		1, 1, 1, 1, 2, 2, 2, 2,
		3, 3, 3, 3, 4, 4, 4, 4,
		5, 5, 5, 5, 0
	];

	static var distBase = [
		1, 2, 3, 4, 5, 7, 9, 13,
		17, 25, 33, 49, 65, 97, 129, 193,
		257, 385, 513, 769, 1025, 1537,
		2049, 3073, 4097, 6145, 8193,
		12289, 16385, 24577
	];

	static var distExtra = [
		0, 0, 0, 0, 1, 1, 2, 2,
		3, 3, 4, 4, 5, 5, 6, 6,
		7, 7, 8, 8, 9, 9, 10, 10,
		11, 11, 12, 12, 13, 13
	];

	public static function run(b:Bytes, ?level:Int = 9):Bytes {

		if (level < 0) level = 0;
		if (level > 9) level = 9;

		var output:Array<Int> = [];

		// ZLIB header
		output.push(0x78);
		output.push(0x01);

		// No compression
		if (level == 0) {

			var pos = 0;

			while (pos < b.length || (b.length == 0 && pos == 0)) {

				var size = b.length - pos;
				if (size > 65535) size = 65535;

				var isFinal = pos + size >= b.length;

				output.push(isFinal ? 1 : 0);

				output.push(size & 255);
				output.push((size >> 8) & 255);

				var inverse = (~size) & 65535;

				output.push(inverse & 255);
				output.push((inverse >> 8) & 255);

				for (i in 0...size) {
					output.push(b.get(pos + i));
				}

				pos += size;

				if (isFinal) break;
			}
		}
		else {

			var bits = new DeflateBits(output);

			// Final block, fixed Huffman
			bits.writeBits(1, 1);
			bits.writeBits(1, 2);

			var n = b.length;

			var head:Array<Int> = [for (i in 0...65536) -1];
			var prev:Array<Int> = [for (i in 0...n) -1];

			var chainLimit = switch (level) {
				case 1: 4;
				case 2: 8;
				case 3: 16;
				case 4: 32;
				case 5: 64;
				case 6: 96;
				case 7: 128;
				case 8: 192;
				default: 256;
			};

			var pos = 0;

			while (pos < n) {

				var bestLength = 0;
				var bestDistance = 0;

				var hash = -1;

				if (pos + 2 < n) {

					hash = hash3(b, pos);

					var candidate = head[hash];
					var attempts = 0;

					var maxLength = n - pos;
					if (maxLength > 258) maxLength = 258;

					while (candidate >= 0 &&
						   attempts < chainLimit) {

						var distance = pos - candidate;

						if (distance > 32768) break;

						if (b.get(candidate) == b.get(pos) &&
							b.get(candidate + 1) == b.get(pos + 1) &&
							b.get(candidate + 2) == b.get(pos + 2)) {

							var length = 3;

							while (length < maxLength &&
								   b.get(candidate + length) ==
								   b.get(pos + length)) {
								length++;
							}

							if (length > bestLength) {
								bestLength = length;
								bestDistance = distance;

								if (length == maxLength) break;
							}
						}

						candidate = prev[candidate];
						attempts++;
					}
				}

				if (bestLength >= 3) {

					writeMatch(bits, bestLength, bestDistance);

					for (i in 0...bestLength) {

						var p = pos + i;

						if (p + 2 < n) {
							var h = hash3(b, p);
							prev[p] = head[h];
							head[h] = p;
						}
					}

					pos += bestLength;
				}
				else {

					writeSymbol(bits, b.get(pos));

					if (hash >= 0) {
						prev[pos] = head[hash];
						head[hash] = pos;
					}

					pos++;
				}
			}

			// End of block
			writeSymbol(bits, 256);

			bits.finish();
		}

		// Adler-32
		var a = 1;
		var c = 0;

		for (i in 0...b.length) {
			a = (a + b.get(i)) % 65521;
			c = (c + a) % 65521;
		}

		var adler = (c << 16) | a;

		output.push((adler >>> 24) & 255);
		output.push((adler >>> 16) & 255);
		output.push((adler >>> 8) & 255);
		output.push(adler & 255);

		var result = Bytes.alloc(output.length);

		for (i in 0...output.length) {
			result.set(i, output[i]);
		}

		return result;
	}

	static inline function hash3(b:Bytes, p:Int):Int {
		return (
			(b.get(p) * 251 +
			 b.get(p + 1)) * 251 +
			 b.get(p + 2)
		) & 65535;
	}

	static function reverse(value:Int, length:Int):Int {

		var result = 0;

		for (i in 0...length) {
			result = (result << 1) | (value & 1);
			value >>= 1;
		}

		return result;
	}

	static function writeSymbol(bits:DeflateBits, symbol:Int):Void {

		var code:Int;
		var length:Int;

		if (symbol <= 143) {
			code = 0x30 + symbol;
			length = 8;
		}
		else if (symbol <= 255) {
			code = 0x190 + symbol - 144;
			length = 9;
		}
		else if (symbol <= 279) {
			code = symbol - 256;
			length = 7;
		}
		else {
			code = 0xC0 + symbol - 280;
			length = 8;
		}

		bits.writeBits(reverse(code, length), length);
	}

	static function writeMatch(
		bits:DeflateBits,
		length:Int,
		distance:Int
	):Void {

		var li = 0;

		while (li < 28 &&
			   length >= lengthBase[li + 1]) {
			li++;
		}

		writeSymbol(bits, 257 + li);

		var le = lengthExtra[li];

		if (le > 0) {
			bits.writeBits(length - lengthBase[li], le);
		}

		var di = 0;

		while (di < 29 &&
			   distance >= distBase[di + 1]) {
			di++;
		}

		bits.writeBits(reverse(di, 5), 5);

		var de = distExtra[di];

		if (de > 0) {
			bits.writeBits(distance - distBase[di], de);
		}
	}
}

private class DeflateBits {

	var output:Array<Int>;
	var buffer:Int = 0;
	var count:Int = 0;

	public function new(output:Array<Int>) {
		this.output = output;
	}

	public function writeBits(value:Int, length:Int):Void {

		buffer |= value << count;
		count += length;

		while (count >= 8) {

			output.push(buffer & 255);

			buffer >>>= 8;
			count -= 8;
		}
	}

	public function finish():Void {

		if (count > 0) {
			output.push(buffer & 255);
			buffer = 0;
			count = 0;
		}
	}
}