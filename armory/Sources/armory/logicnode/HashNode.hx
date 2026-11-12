package armory.logicnode;

import haxe.io.Bytes;
import haxe.crypto.Md5;
import haxe.crypto.Sha1;
import haxe.crypto.Sha224;
import haxe.crypto.Sha256;
import haxe.crypto.Crc32;
import haxe.crypto.Adler32;
import haxe.crypto.Hmac;

class HashNode extends LogicNode {

	public var property0: String;
	var hash: String = "";

	public function new(tree:LogicTree) {
		super(tree);
	}

	override function run(from:Int):Void {
		var input: String = inputs[1].get();

		hash = switch (property0) {
			case "MD5": Md5.encode(input);
			case "SHA1": Sha1.encode(input);
			case "SHA224": Sha224.encode(input);
			case "CRC32": StringTools.hex(Crc32.make(Bytes.ofString(input)), 8).toLowerCase();
			case "ADLER32": StringTools.hex(Adler32.make(Bytes.ofString(input)), 8).toLowerCase();
			case "HMAC_MD5": new Hmac(HashMethod.MD5).make(Bytes.ofString(inputs[2].get()), Bytes.ofString(input)).toHex();
			case "HMAC_SHA1": new Hmac(HashMethod.SHA1).make(Bytes.ofString(inputs[2].get()), Bytes.ofString(input)).toHex();
			case "HMAC_SHA256": new Hmac(HashMethod.SHA256).make(Bytes.ofString(inputs[2].get()), Bytes.ofString(input)).toHex();
			default: Sha256.encode(input);
		};

		runOutput(0);
	}

	override function get(from:Int):Dynamic {
		return from == 1 ? hash : hash.length;
	}
}