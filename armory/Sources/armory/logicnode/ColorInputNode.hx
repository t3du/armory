
package armory.logicnode;

import iron.math.Vec4;

class ColorInputNode extends LogicNode {

	var selectedColor:Vec4;

	public function new(tree:LogicTree) {
		super(tree);
	}

	override function run(from:Int) {

		var msg:String = inputs[1].get();
		var defaultColor:Vec4 = inputs[2].get();

		selectedColor = new Vec4(
			defaultColor.x,
			defaultColor.y,
			defaultColor.z,
			defaultColor.w
		);

		#if kha_krom

		var save = Krom.getFilesLocation() + "/colorinput.txt";
		var escapedSave = save.split("'").join("''");

		var r = channel(defaultColor.x);
		var g = channel(defaultColor.y);
		var b = channel(defaultColor.z);

		var ps =
			"Add-Type -AssemblyName System.Windows.Forms; " +
			"Add-Type -AssemblyName System.Drawing; " +

			"$save = '" + escapedSave + "'; " +

			"Remove-Item -LiteralPath $save -ErrorAction SilentlyContinue; " +

			"$d = New-Object System.Windows.Forms.ColorDialog; " +
			"$d.FullOpen = $true; " +

			"$d.Color = [System.Drawing.Color]::FromArgb(" +
			r + "," + g + "," + b + "); " +

			"if ($d.ShowDialog() -eq " +
			"[System.Windows.Forms.DialogResult]::OK) { " +

			"$c = $d.Color; " +

			"[System.IO.File]::WriteAllText($save, " +
			"('{0},{1},{2}' -f $c.R,$c.G,$c.B)); " +

			"} else { " +

			"[System.IO.File]::WriteAllText($save, 'CANCEL'); " +

			"}";

		Krom.sysCommand(
			'powershell.exe -STA -NoProfile -Command "' + ps + '"'
		);

		var bytes = Krom.loadBlob("colorinput.txt");

		if (bytes != null) {

			var result = StringTools.trim(
				haxe.io.Bytes.ofData(bytes).toString()
			);

			if (result != "CANCEL") {

				var rgb = result.split(",");

				if (rgb.length == 3) {

					selectedColor = new Vec4(
						Std.parseInt(rgb[0]) / 255,
						Std.parseInt(rgb[1]) / 255,
						Std.parseInt(rgb[2]) / 255,
						defaultColor.w
					);

					runOutput(0);
					return;
				}
			}
		}

		runOutput(1);

		#elseif kha_html5

		var dialog:Dynamic =
			js.Browser.document.createElement("dialog");

		dialog.style.width = "300px";
		dialog.style.border = "1px solid #888";
		dialog.style.borderRadius = "8px";
		dialog.style.padding = "20px";
		dialog.style.background = "#f0f0f0";
		dialog.style.color = "#222";
		dialog.style.fontFamily = "Arial";
		dialog.style.boxShadow = "0 5px 25px #0005";
		dialog.style.marginTop = "60px";

		var title = js.Browser.document.createElement("p");
		title.textContent = msg;

		var picker: js.html.InputElement =
			cast js.Browser.document.createElement("input");

		picker.type = "color";
		picker.value = colorToHex(defaultColor);

		picker.style.width = "100%";
		picker.style.height = "40px";

		var buttons = js.Browser.document.createElement("div");
		buttons.style.textAlign = "right";
		buttons.style.marginTop = "20px";

		var ok = js.Browser.document.createElement("button");
		ok.textContent = "Ok";

		var cancel = js.Browser.document.createElement("button");
		cancel.textContent = "Cancel";

		buttons.appendChild(ok);
		buttons.appendChild(cancel);

		dialog.appendChild(title);
		dialog.appendChild(picker);
		dialog.appendChild(buttons);

		js.Browser.document.body.appendChild(dialog);

		var finished = false;

		var finish = function(accepted:Bool) {

			if (finished) return;
			finished = true;

			if (accepted) {

				selectedColor = hexToColor(
					picker.value,
					defaultColor.w
				);
			}

			dialog.close();

			js.Browser.document.body.removeChild(dialog);

			js.Browser.window.requestAnimationFrame(function(_) {

				js.Browser.window.requestAnimationFrame(function(_) {

					runOutput(accepted ? 0 : 1);

				});

			});
		};

		ok.onclick = function(_) {
			finish(true);
		};

		cancel.onclick = function(_) {
			finish(false);
		};

		dialog.oncancel = function(e) {

			e.preventDefault();

			finish(false);
		};

		dialog.showModal();

		#else

		runOutput(1);

		#end
	}

	override function get(from:Int):Dynamic {
		return selectedColor;
	}

	function channel(value:Float):Int {

		return Std.int(
			Math.max(
				0,
				Math.min(255, Math.round(value * 255))
			)
		);
	}

	function colorToHex(c:Vec4):String {

		return "#" +
			StringTools.hex(channel(c.x), 2) +
			StringTools.hex(channel(c.y), 2) +
			StringTools.hex(channel(c.z), 2);
	}

	function hexToColor(hex:String, alpha:Float):Vec4 {

		var r = Std.parseInt("0x" + hex.substr(1, 2));
		var g = Std.parseInt("0x" + hex.substr(3, 2));
		var b = Std.parseInt("0x" + hex.substr(5, 2));

		return new Vec4(
			r / 255,
			g / 255,
			b / 255,
			alpha
		);
	}
}
