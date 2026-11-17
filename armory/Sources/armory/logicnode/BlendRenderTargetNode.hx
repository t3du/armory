package armory.logicnode;

import kha.graphics4.PipelineState;
import kha.graphics4.BlendingFactor;
import kha.graphics4.BlendingOperation;
import kha.graphics4.Graphics2 as G4G2;
import kha.graphics4.Graphics2.PipelineCache;
import kha.graphics4.Graphics2.SimplePipelineCache;
import armory.renderpath.RenderToTexture;

typedef BlendPipelines = {
	colorPipe: PipelineState,
	imagePipe: PipelineState,
	textPipe: PipelineState,
	colorCache: PipelineCache,
	imageCache: PipelineCache,
	textCache: PipelineCache
}

class BlendRenderTargetNode extends LogicNode {

	public var property0: String; // Blend mode: Normal, Erase, Additive, Multiply

	static var pipelines: Map<String, BlendPipelines> = new Map();

	public function new(tree: LogicTree) {
		super(tree);
	}

	static function applyBlending(pipe: PipelineState, mode: String, isText: Bool = false) {
		switch (mode) {
			case "Normal":
				pipe.blendSource = SourceAlpha;
				pipe.blendDestination = InverseSourceAlpha;
				pipe.blendOperation = Add;
				pipe.alphaBlendSource = SourceAlpha;
				pipe.alphaBlendDestination = InverseSourceAlpha;
				pipe.alphaBlendOperation = Add;

			case "Erase":
				// Erases destination where source is drawn
				pipe.blendSource = BlendZero;
				pipe.blendDestination = InverseSourceAlpha;
				pipe.blendOperation = Add;
				pipe.alphaBlendSource = BlendZero;
				pipe.alphaBlendDestination = InverseSourceAlpha;
				pipe.alphaBlendOperation = Add;

			case "Additive":
				// Adds source color to destination
				pipe.blendSource = SourceAlpha;
				pipe.blendDestination = BlendOne;
				pipe.blendOperation = Add;
				pipe.alphaBlendSource = SourceAlpha;
				pipe.alphaBlendDestination = BlendOne;
				pipe.alphaBlendOperation = Add;

			case "Multiply":
				// Multiplies source and destination colors (shadows, tints)
				if (isText) {
					pipe.blendSource = SourceAlpha;
					pipe.blendDestination = InverseSourceAlpha;
					pipe.blendOperation = Add;
					pipe.alphaBlendSource = SourceAlpha;
					pipe.alphaBlendDestination = InverseSourceAlpha;
					pipe.alphaBlendOperation = Add;
				} else {
					pipe.blendSource = DestinationColor;
					pipe.blendDestination = BlendZero;
					pipe.blendOperation = Add;
					pipe.alphaBlendSource = DestinationAlpha;
					pipe.alphaBlendDestination = BlendZero;
					pipe.alphaBlendOperation = Add;
				}
		}
	}

	static function getOrCreatePipelines(mode: String): Null<BlendPipelines> {
		if (mode == "Normal") return null;
		if (pipelines.exists(mode)) return pipelines.get(mode);

		// 1. Color pipeline (primitives: circles, rects, triangles, lines)
		var sColor = G4G2.createColoredVertexStructure();
		var pipeColor = G4G2.createColoredPipeline(sColor);
		applyBlending(pipeColor, mode, false);
		pipeColor.compile();

		// 2. Image pipeline (drawImage, render targets)
		var sImage = G4G2.createImageVertexStructure();
		var pipeImage = G4G2.createImagePipeline(sImage);
		applyBlending(pipeImage, mode, false);
		pipeImage.compile();

		// 3. Text pipeline (drawString, drawCharacters)
		var sText = G4G2.createTextVertexStructure();
		var pipeText = G4G2.createTextPipeline(sText);
		applyBlending(pipeText, mode, true);
		pipeText.compile();

		var res: BlendPipelines = {
			colorPipe: pipeColor,
			imagePipe: pipeImage,
			textPipe: pipeText,
			colorCache: new SimplePipelineCache(pipeColor, false),
			imageCache: new SimplePipelineCache(pipeImage, true),
			textCache: new SimplePipelineCache(pipeText, true)
		};

		pipelines.set(mode, res);
		return res;
	}

	inline static function applyPipelines(g4: G4G2, p: BlendPipelines) {
		@:privateAccess g4.coloredPainter.pipeline = p.colorCache;
		@:privateAccess g4.imagePainter.pipeline = p.imageCache;
		@:privateAccess g4.textPainter.pipeline = p.textCache;
		@:privateAccess g4.lastPipeline = p.colorPipe;
	}

	inline static function resetPipelines(g4: G4G2) {
		@:privateAccess g4.coloredPainter.pipeline = null;
		@:privateAccess g4.imagePainter.pipeline = null;
		@:privateAccess g4.textPainter.pipeline = null;
		@:privateAccess g4.lastPipeline = null;
	}

	override function run(from: Int) {
		RenderToTexture.ensure2DContext("BlendRenderTargetNode");

		final mode = property0;
		final revert: Bool = inputs[1].get();

		var g4: G4G2 = Std.isOfType(RenderToTexture.g, G4G2) ? cast RenderToTexture.g : null;

		if (g4 != null) {
			g4.flush();
			if (mode == "Normal") {
				resetPipelines(g4);
			} else {
				var p = getOrCreatePipelines(mode);
				if (p != null) {
					applyPipelines(g4, p);
				}
			}
		} else {
			RenderToTexture.g.flush();
			if (mode == "Normal") {
				RenderToTexture.g.pipeline = null;
			} else {
				var p = getOrCreatePipelines(mode);
				if (p != null) RenderToTexture.g.pipeline = p.colorPipe;
			}
		}

		// Execute connected draw nodes
		runOutput(0);

		// Revert to default pipeline if enabled
		if (revert) {
			if (g4 != null) {
				g4.flush();
				resetPipelines(g4);
			} else {
				RenderToTexture.g.flush();
				RenderToTexture.g.pipeline = null;
			}
		}
	}
}
