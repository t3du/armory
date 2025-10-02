package armory.logicnode;

import iron.object.CameraObject;
import kha.Color;

import iron.format.gif.GifEncoder;

class WriteGifNode extends LogicNode {

	var file: String;
	var camera: CameraObject;
	var renderTarget: kha.Image;
	//var texAux: kha.Image;

	var width: Int;
	var height: Int;
	var tx: Int;
	var ty: Int;
	var tw: Int;
	var th: Int;

	var r2d: Bool;

	var encoder: iron.format.gif.GifEncoder;
	var frames: Array<haxe.io.UInt8Array>;
	var bo: haxe.io.BytesOutput;
	var fdur: Float;

	var duration: Float;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		if (from == 0){
		// Relative or absolute path to file
		file = inputs[2].get();
		camera = inputs[3].get();

		width = inputs[4].get();
		height = inputs[5].get();
		tx = inputs[6].get();
		ty = inputs[7].get();
		tw = inputs[8].get();
		th = inputs[9].get();
		r2d = inputs[10].get();

		fdur = inputs[11].get();

		//assert(Error, iron.App.w() % inputs[3].get() == 0 && iron.App.h() % inputs[4].get() == 0, "Aspect ratio must match display resolution ratio");

		renderTarget = kha.Image.createRenderTarget(width, height,
			kha.graphics4.TextureFormat.RGBA32,
			kha.graphics4.DepthStencilFormat.NoDepthAndStencil);

		//if (r2d)
		//	texAux = 

		frames = [];
		bo = new haxe.io.BytesOutput();
		duration = 0.0;

        encoder = new iron.format.gif.GifEncoder(tw, th, fdur, -1, 10); //GifRepeat.Infinite, GifQuality.High

        encoder.start(bo);

        tree.notifyOnRender(render);

		}
		else{

			if (frames != null){

				encoder.commit(bo);

				#if kha_krom
				Krom.fileSaveBytes(Krom.getFilesLocation() +  "/" + file, bo.getBytes().getData());
		
				#elseif kha_html5
				var blob = new js.html.Blob([bo.getBytes().getData()], {type: "application"});
		        var url = js.html.URL.createObjectURL(blob);
		        var a = cast(js.Browser.document.createElement("a"), js.html.AnchorElement);
		        a.href = url;
		        a.download = file;
		        a.click();
		        js.html.URL.revokeObjectURL(url);
				#end

				runOutput(0);

				tree.removeRender(render);

				renderTarget.unload();
				//if (r2d)
					//texAux.unload();
				frames = null;
				bo = null;
			}

		}
		
	}

	function render(g: kha.graphics4.Graphics) {

		duration += iron.system.Time.delta;
		
		if (duration < fdur)
			return;
		
		duration = 0;

		var ready = false;
		final sceneCam = iron.Scene.active.camera;
		final oldRT = camera.renderTarget;

		iron.Scene.active.camera = camera;
		camera.renderTarget = renderTarget;

		camera.renderFrame(g);

		var tex = camera.renderTarget;

		camera.renderTarget = oldRT;
		iron.Scene.active.camera = sceneCam;

		if (r2d){

			tex = kha.Image.createRenderTarget(width, height,
				kha.graphics4.TextureFormat.RGBA32,
				kha.graphics4.DepthStencilFormat.NoDepthAndStencil);

			//texAux;

			tex.g2.begin(true, Color.Transparent);

			tex.g2.color = Color.White;
			tex.g2.drawScaledImage(renderTarget, 0, 0, width, height);

			var scl = width/ iron.App.w();

			if (kha.Image.renderTargetsInvertedY()){
				tex.g2.scale(scl, -scl);
				tex.g2.translate(0, height);
			}
			else
				tex.g2.scale(scl, scl);

			for (f in @:privateAccess iron.App.traitRenders2D){
		    	f(tex.g2);
		    }
		    
		    tex.g2.end();

		}

		var pixels = tex.getPixels();

		for (i in 0...pixels.length){
			if (pixels.get(i) != 0){ ready = true; break; }
		}

		//wait for getPixels ready
		if (ready) { 

			var rgb = new haxe.io.UInt8Array(tw * th * 3);
			for (j in ty...ty + th) {
				for (i in tx...tx + tw) {
					var k = j * tex.width + i;
					var m =  (j - ty) * tw + i - tx;
					
					#if kha_krom
					var l = k;
					#elseif kha_html5
					var l = (tex.height - j) * tex.width + i;
					#end

					//ARGB 0xff
					rgb.set(m * 3 + 0, pixels.get(l * 4 + 0)); 
					rgb.set(m * 3 + 1, pixels.get(l * 4 + 1));
					rgb.set(m * 3 + 2, pixels.get(l * 4 + 2));
				}
			}

			var frame: GifFrame = {
	            delay: fdur,
	            flippedY: false,
	            data: rgb
	        }

			encoder.add(bo, frame);

		}

	}

}
