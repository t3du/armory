package armory.logicnode;

import iron.math.Vec4;
import kha.Image;
import kha.Color;
import armory.renderpath.RenderToTexture;

import iron.format.gif.Reader;
import iron.format.gif.Data;
import iron.format.gif.Tools;

import haxe.io.Bytes;
import haxe.io.BytesInput;

import armory.system.Event; 

class DrawGifNode extends LogicNode {
	var data:Data = null;
	var frames:Int = 0;
	var img: Array<Image> = [];
	var lastImgName = "";
	var duration = 0.0;
	var index = 0;
	var i = 0;

	public function new(tree: LogicTree) {
		super(tree);

		Event.add('load', function() {
			var extractedBytes:Bytes = Tools.extractFullRGBA(data, i);
			img.push(kha.Image.fromBytes(extractedBytes, data.logicalScreenDescriptor.width, data.logicalScreenDescriptor.height, kha.graphics4.TextureFormat.RGBA32));
		});

		tree.notifyOnRemove(onRemove);

	}

	function onRemove() {
		Event.remove('load');
	}

	override function run(from: Int) {
		if (from == 0){

			if (data == null){
				runOutput(0);
				return;
			}

			RenderToTexture.ensure2DContext("DrawGifNode");

			final colorVec: Vec4 = inputs[3].get();
			final anchorH: Int = inputs[4].get();
			final anchorV: Int = inputs[5].get();
			final x: Float = inputs[6].get();
			final y: Float = inputs[7].get();
			final width: Float = inputs[8].get();
			final height: Float = inputs[9].get();
			final angle: Float = inputs[10].get();

			var sindex: Int = inputs[11].get();
			var eindex: Int = inputs[12].get();
			final fdur: Float = inputs[13].get();
			final loop: Bool = inputs[14].get();

			final drawx = x - 0.5 * width * anchorH;
			final drawy = y - 0.5 * height * anchorV;

			if(eindex == -1 || eindex > frames)
				eindex = frames;

			if(sindex < 0 || sindex > frames)
				sindex = 0;

			if (index < sindex || index > eindex)
				index = sindex;

			duration += iron.system.Time.delta;
			if (duration >= fdur){
				if (index < eindex)
					index += 1;
				else 
					if (loop) index = sindex;
				duration = 0;
				if (i < eindex){
					++i;
					Event.send('load');
				}
			}

			if (img.length > (index - sindex)){
				RenderToTexture.g.rotate(angle, x, y);
				RenderToTexture.g.color = Color.fromFloats(colorVec.x, colorVec.y, colorVec.z, colorVec.w);		
				RenderToTexture.g.drawScaledImage(img[index-sindex], drawx, drawy, width, height);
				RenderToTexture.g.rotate(-angle, x, y);
			}

			runOutput(0);
		}
		else{
			final imgName: String = inputs[2].get();
			if (imgName != lastImgName) {
				// Load new image
				lastImgName = imgName;
				img = [];
				i = inputs[11].get();
				index = i;
				iron.data.Data.getBlob(imgName, (blob: kha.Blob) -> {
					var bytes: Bytes = blob.toBytes();
					var input: BytesInput = new BytesInput(bytes);
					data = new Reader(input).read();
					frames = Tools.framesCount(data);
					if (i > frames) return;
					/*
					for (i in 0...frames){
						//var frame:Frame = Tools.frame(data, i); frame.width, frame.height
						var extractedBytes:Bytes = Tools.extractFullRGBA(data, i); //Tools.extractRGBA(data, i); 
						img.push(kha.Image.fromBytes(extractedBytes, data.logicalScreenDescriptor.width, data.logicalScreenDescriptor.height, kha.graphics4.TextureFormat.RGBA32));
					}*/
					var extractedBytes:Bytes = Tools.extractFullRGBA(data, i);
					img.push(kha.Image.fromBytes(extractedBytes, data.logicalScreenDescriptor.width, data.logicalScreenDescriptor.height, kha.graphics4.TextureFormat.RGBA32));
					++i;
					Event.send('load');
				});
			}

		}
	}

	override function get(from: Int): Dynamic {
		if (from == 1)
			return frames;
		else
			return index;
	}
}
