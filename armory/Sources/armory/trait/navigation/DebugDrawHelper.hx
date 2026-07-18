package armory.trait.navigation;

import kha.FastFloat;
import kha.System;

import iron.math.Vec4;

#if arm_ui
import armory.ui.Canvas;
#end

#if arm_navigation
class DebugDrawHelper {
	final navigation: Navigation;
	final lines: Array<LineData> = [];
	final texts: Array<TextData> = [];

	var font: kha.Font = null;

	var debugMode: Navigation.DebugDrawMode = NoDebug;

	public function new(navigation: Navigation) {
		this.navigation = navigation;

		#if arm_ui
		iron.data.Data.getFont(Canvas.defaultFontName, function(defaultFont: kha.Font) {
			font = defaultFont;
		});
		#end

		iron.App.notifyOnRender2D(onRender);
	}

	public function drawLine(from: Vec4, to: Vec4, color: kha.Color) {

		final fromScreenSpace = worldToScreenFast(new Vec4().setFrom(from));
		final toScreenSpace =  worldToScreenFast(new Vec4().setFrom(to));

		// For now don't draw lines if any point is outside of clip space z,
		// investigate how to clamp lines to clip space borders
		if (fromScreenSpace.w == 1 && toScreenSpace.w == 1) {
			lines.push({
				fromX: fromScreenSpace.x,
				fromY: fromScreenSpace.y,
				toX: toScreenSpace.x,
				toY: toScreenSpace.y,
				color: color
			});
		}
	}

	public function setDebugMode(debugMode: Navigation.DebugDrawMode) {
		this.debugMode = debugMode;
	}

	public function getDebugMode(): Navigation.DebugDrawMode {
		return debugMode;
	}

	function onRender(g: kha.graphics2.Graphics) {
		
		if (getDebugMode() == NoDebug) {
			return;
		}

		for(navMesh in Navigation.active.navMeshes) {
			navMesh.drawDebugMesh(this);

			if (font != null) {
				final screenPos = worldToScreenFast(new Vec4().setFrom(navMesh.object.transform.loc));

				if (screenPos.w == 1) {
					texts.push({
						x: screenPos.x,
						y: screenPos.y,
						color: kha.Color.White,
						text: navMesh.navMeshId
					});
				}
			}
		}

		g.opacity = 1.0;

		for (line in lines) {
			g.color = line.color;
			g.drawLine(line.fromX, line.fromY, line.toX, line.toY, 1.0);
		}
		lines.resize(0);

		if (font != null) {
			g.font = font;
			g.fontSize = 18;

			for (text in texts) {
				g.color = text.color;
				g.drawString(text.text, text.x, text.y);
			}

			texts.resize(0);
		}
	}

	/**
		Transform a world coordinate vector into screen space and store the
		result in the input vector's x and y coordinates. The w coordinate is
		set to 0 if the input vector is outside the active camera's far and near
		planes, and 1 otherwise.
	**/
	inline function worldToScreenFast(loc: Vec4): Vec4 {
		final cam = iron.Scene.active.camera;
		loc.w = 1.0;
		loc.applyproj(cam.VP);

		if (loc.z < -1 || loc.z > 1) {
			loc.w = 0.0;
		}
		else {
			loc.x = (loc.x + 1) * 0.5 * System.windowWidth();
			loc.y = (1 - loc.y) * 0.5 * System.windowHeight();
			loc.w = 1.0;
		}

		return loc;
	}
}

@:structInit
class LineData {
	public var fromX: FastFloat;
	public var fromY: FastFloat;
	public var toX: FastFloat;
	public var toY: FastFloat;
	public var color: kha.Color;
}

@:structInit
class TextData {
	public var x: FastFloat;
	public var y: FastFloat;
	public var color: kha.Color;
	public var text: String;
}
#end
