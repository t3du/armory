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

		selectedColor = new Vec4(defaultColor.x, defaultColor.y, defaultColor.z, defaultColor.w);

		#if kha_krom

		var save = Krom.getFilesLocation() + "/colorinput.txt";
		var escapedSave = save.split("'").join("''");
		var r = channel(defaultColor.x);
		var g = channel(defaultColor.y);
		var b = channel(defaultColor.z);
		var a = channel(defaultColor.w);
		var title = msg.split("'").join("''");

		var ps =
			"Add-Type -AssemblyName System.Windows.Forms; " +
			"Add-Type -AssemblyName System.Drawing; " +
			"$save = '" + escapedSave + "'; " +
			"$form = New-Object System.Windows.Forms.Form; " +
			"$form.Text = '" + title + "'; $form.Width = 390; $form.Height = 245; " +
			"$form.StartPosition = 'CenterScreen'; $form.FormBorderStyle = 'FixedDialog'; $form.MaximizeBox = $false; " +
			"$dialog = New-Object System.Windows.Forms.ColorDialog; $dialog.FullOpen = $true; $dialog.AnyColor = $true; " +
			"$dialog.Color = [System.Drawing.Color]::FromArgb(" + r + "," + g + "," + b + "); " +

			"$preview = New-Object System.Windows.Forms.Panel; " +
			"$preview.Left = 20; $preview.Top = 15; $preview.Width = 340; $preview.Height = 35; " +
			"$preview.BackColor = $dialog.Color; $form.Controls.Add($preview); " +

			"$pick = New-Object System.Windows.Forms.Button; " +
			"$pick.Text = '" + title + "'; $pick.Left = 20; $pick.Top = 60; $pick.Width = 340; $pick.Height = 30; " +
			"$pick.Add_Click({ if ($dialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) { $preview.BackColor = $dialog.Color; } }); " +
			"$form.Controls.Add($pick); " +

			"$alphaPanel = New-Object System.Windows.Forms.Panel; " +
			"$alphaPanel.Left = 20; $alphaPanel.Top = 105; $alphaPanel.Width = 340; $alphaPanel.Height = 45; " +

			"$label = New-Object System.Windows.Forms.Label; " +
			"$label.Text = 'Alpha'; $label.Left = 0; $label.Top = -5; $label.Width = 48; $label.Height = 35; " +
			"$label.TextAlign = 'MiddleLeft'; $alphaPanel.Controls.Add($label); " +

			"$alpha = New-Object System.Windows.Forms.TrackBar; " +
			"$alpha.Left = 48; $alpha.Top = 0; $alpha.Width = 245; $alpha.Height = 45; " +
			"$alpha.Minimum = 0; $alpha.Maximum = 255; $alpha.TickFrequency = 25; $alpha.TickStyle = 'None'; " +
			"$alpha.Value = " + a + "; $alphaPanel.Controls.Add($alpha); " +

			"$alphaValue = New-Object System.Windows.Forms.Label; " +
			"$alphaValue.Left = 295; $alphaValue.Top = -5; $alphaValue.Width = 45; $alphaValue.Height = 35; " +
			"$alphaValue.TextAlign = 'MiddleRight'; $alphaValue.Text = '" + a + "'; $alphaPanel.Controls.Add($alphaValue); " +

			"$form.Controls.Add($alphaPanel); " +
			"$alpha.Add_ValueChanged({ $alphaValue.Text = $alpha.Value.ToString(); }); " +

			"$ok = New-Object System.Windows.Forms.Button; " +
			"$ok.Text = 'OK'; $ok.Left = 195; $ok.Top = 165; $ok.Width = 75; " +
			"$ok.DialogResult = [System.Windows.Forms.DialogResult]::OK; " +

			"$cancel = New-Object System.Windows.Forms.Button; " +
			"$cancel.Text = 'Cancel'; $cancel.Left = 280; $cancel.Top = 165; $cancel.Width = 75; " +
			"$cancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel; " +

			"$form.Controls.Add($ok); $form.Controls.Add($cancel); " +
			"$form.AcceptButton = $ok; $form.CancelButton = $cancel; " +

			"$result = $form.ShowDialog(); " +
			"if ($result -eq [System.Windows.Forms.DialogResult]::OK) { " +
			"[System.IO.File]::WriteAllText($save, ('{0},{1},{2},{3}' -f $dialog.Color.R,$dialog.Color.G,$dialog.Color.B,$alpha.Value)); " +
			"} else { [System.IO.File]::WriteAllText($save, 'CANCEL'); }; " +
			"$form.Dispose(); $dialog.Dispose();";

		Krom.sysCommand('powershell.exe -STA -NoProfile -Command "' + ps + '"');

		var bytes = Krom.loadBlob("colorinput.txt");

		if (bytes != null) {
			var result = StringTools.trim(haxe.io.Bytes.ofData(bytes).toString());

			if (result != "CANCEL") {
				var rgba = result.split(",");

				if (rgba.length == 4) {
					selectedColor = new Vec4(
						Std.parseInt(rgba[0]) / 255,
						Std.parseInt(rgba[1]) / 255,
						Std.parseInt(rgba[2]) / 255,
						Std.parseInt(rgba[3]) / 255
					);
					runOutput(0);
					return;
				}
			}
		}

		runOutput(1);

		#elseif kha_html5

		var dialog:Dynamic = js.Browser.document.createElement("dialog");

		dialog.style.width = "300px";
		dialog.style.border = "1px solid #888";
		dialog.style.borderRadius = "8px";
		dialog.style.padding = "20px";
		dialog.style.background = "#f0f0f0";
		dialog.style.color = "#222";
		dialog.style.fontFamily = "Arial";
		dialog.style.boxShadow = "0 5px 25px #0005";
		dialog.style.marginTop = "60px";
		dialog.style.boxSizing = "border-box";

		var title = js.Browser.document.createElement("p");
		title.textContent = msg;

		var picker:js.html.InputElement = cast js.Browser.document.createElement("input");
		picker.type = "color";
		picker.value = colorToHex(defaultColor);
		picker.style.display = "block";
		picker.style.width = "100%";
		picker.style.height = "45px";
		picker.style.marginBottom = "20px";
		picker.style.boxSizing = "border-box";

		var alphaContainer = js.Browser.document.createElement("div");
		alphaContainer.style.width = "100%";
		alphaContainer.style.marginTop = "10px";
		alphaContainer.style.marginBottom = "20px";
		alphaContainer.style.boxSizing = "border-box";

		var alphaHeader = js.Browser.document.createElement("div");
		alphaHeader.style.display = "flex";
		alphaHeader.style.flexDirection = "row";
		alphaHeader.style.alignItems = "center";
		alphaHeader.style.justifyContent = "space-between";
		alphaHeader.style.marginBottom = "2px";

		var alphaTitle = js.Browser.document.createElement("span");
		alphaTitle.textContent = "Alpha";
		alphaTitle.style.fontSize = "13px";
		alphaTitle.style.fontWeight = "normal";
		alphaTitle.style.color = "#333";

		var alphaValue = js.Browser.document.createElement("span");
		alphaValue.textContent = Std.string(channel(defaultColor.w));
		alphaValue.style.fontSize = "13px";
		alphaValue.style.fontWeight = "bold";
		alphaValue.style.color = "#555";
		alphaValue.style.minWidth = "30px";
		alphaValue.style.textAlign = "right";

		alphaHeader.appendChild(alphaTitle);
		alphaHeader.appendChild(alphaValue);

		var alphaPicker:js.html.InputElement = cast js.Browser.document.createElement("input");
		alphaPicker.type = "range";
		alphaPicker.min = "0";
		alphaPicker.max = "255";
		alphaPicker.step = "1";
		alphaPicker.value = Std.string(channel(defaultColor.w));
		alphaPicker.style.display = "block";
		alphaPicker.style.width = "100%";
		alphaPicker.style.height = "38px";
		alphaPicker.style.margin = "0";
		alphaPicker.style.padding = "0";
		alphaPicker.style.cursor = "pointer";

		alphaContainer.appendChild(alphaHeader);
		alphaContainer.appendChild(alphaPicker);

		alphaPicker.oninput = function(_) {
			alphaValue.textContent = alphaPicker.value;
		};

		var buttons = js.Browser.document.createElement("div");
		buttons.style.display = "flex";
		buttons.style.justifyContent = "flex-end";
		buttons.style.gap = "8px";
		buttons.style.marginTop = "20px";

		var ok = js.Browser.document.createElement("button");
		ok.textContent = "Ok";

		var cancel = js.Browser.document.createElement("button");
		cancel.textContent = "Cancel";

		buttons.appendChild(ok);
		buttons.appendChild(cancel);

		dialog.appendChild(title);
		dialog.appendChild(picker);
		dialog.appendChild(alphaContainer);
		dialog.appendChild(buttons);

		js.Browser.document.body.appendChild(dialog);

		var finished = false;

		var finish = function(accepted:Bool) {
			if (finished) return;
			finished = true;

			if (accepted) {
				selectedColor = hexToColor(
					picker.value,
					Std.parseInt(alphaPicker.value) / 255
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
		return Std.int(Math.max(0, Math.min(255, Math.round(value * 255))));
	}

	function colorToHex(c:Vec4):String {
		return "#" + StringTools.hex(channel(c.x), 2) +
			StringTools.hex(channel(c.y), 2) +
			StringTools.hex(channel(c.z), 2);
	}

	function hexToColor(hex:String, alpha:Float):Vec4 {
		var r = Std.parseInt("0x" + hex.substr(1, 2));
		var g = Std.parseInt("0x" + hex.substr(3, 2));
		var b = Std.parseInt("0x" + hex.substr(5, 2));
		return new Vec4(r / 255, g / 255, b / 255, alpha);
	}
}