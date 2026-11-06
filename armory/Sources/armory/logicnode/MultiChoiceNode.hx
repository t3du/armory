package armory.logicnode;

class MultiChoiceNode extends LogicNode {

	var options:Array<String>;
	var defaults:Array<String>;
	var selected:Array<String>;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {

		var msg:String = inputs[1].get();
		options = inputs[2].get();
		defaults = inputs[3].get();

		if (options == null) options = [];
		if (defaults == null) defaults = [];

		selected = [];
	
		#if kha_krom

		var save = Krom.getFilesLocation() + "/multichoice.txt";

		var escapedMsg = msg.split("'").join("''");
		var escapedSave = save.split("'").join("''");

		var optionList = "";

		for (option in options) {
			var escaped = option.split("'").join("''");
			optionList += "'" + escaped + "',";
		}

		if (optionList.length > 0)
			optionList = optionList.substr(0, optionList.length - 1);

		var psCommand =
			"powershell -STA -NoProfile -Command \"" +

			"Add-Type -AssemblyName System.Windows.Forms; " +
			"Add-Type -AssemblyName System.Drawing; " +

			"$save = '" + escapedSave + "'; " +
			"Remove-Item -LiteralPath $save -ErrorAction SilentlyContinue; " +

			"$options = @(" + optionList + "); " +

			"$form = New-Object System.Windows.Forms.Form; " +
			"$form.Text = '" + Main.projectName + "'; " +
			"$form.StartPosition = 'CenterScreen'; " +
			"$form.BackColor = [System.Drawing.Color]::FromArgb(240,240,240); " +
			"$form.ForeColor = [System.Drawing.Color]::FromArgb(34,34,34); " +
			"$form.Font = New-Object System.Drawing.Font('Arial', 9); " +

			"$graphics = $form.CreateGraphics(); " +
			"$maxTextWidth = 0; " +

			"foreach ($option in $options) { " +
			"$size = $graphics.MeasureString([string]$option, $form.Font); " +
			"$maxTextWidth = [Math]::Max($maxTextWidth, $size.Width); " +
			"} " +

			"$messageSize = $graphics.MeasureString('" + escapedMsg + "', $form.Font); " +

			"$formWidth = [Math]::Max(340, [int][Math]::Ceiling([Math]::Max($maxTextWidth, $messageSize.Width)) + 100); " +
			"$form.Width = $formWidth; " +

			"$label = New-Object System.Windows.Forms.Label; " +
			"$label.Text = '" + escapedMsg + "'; " +
			"$label.Left = 15; " +
			"$label.Top = 12; " +
			"$label.Width = $formWidth - 45; " +
			"$label.Height = 30; " +
			"$label.AutoSize = $false; " +
			"$form.Controls.Add($label); " +

			"$panel = New-Object System.Windows.Forms.Panel; " +
			"$panel.Left = 10; " +
			"$panel.Top = 50; " +
			"$panel.Width = $formWidth - 35; " +
			"$panel.AutoScroll = $true; " +
			"$panel.BorderStyle = 'None'; " +
			"$panel.BackColor = [System.Drawing.Color]::FromArgb(240,240,240); " +
			"$form.Controls.Add($panel); " +

			"$checks = @(); " +
			"$currentTop = 5; " +
			"$spacing = 8; " +
			"$rowHeight = 28; " +

			"foreach ($option in $options) { " +

			"$row = New-Object System.Windows.Forms.Panel; " +
			"$row.Left = 0; " +
			"$row.Top = $currentTop; " +
			"$row.Width = $formWidth - 55; " +
			"$row.Height = $rowHeight; " +
			"$row.BackColor = [System.Drawing.Color]::FromArgb(240,240,240); " +

			"$check = New-Object System.Windows.Forms.CheckBox; " +
			"$check.Left = 5; " +
			"$check.Top = 5; " +
			"$check.Width = 18; " +
			"$check.Height = 18; " +
			"$check.AutoSize = $false; " +
			"$check.UseVisualStyleBackColor = $false; " +
			"$check.FlatStyle = 'Flat'; " +
			"$check.BackColor = [System.Drawing.Color]::FromArgb(240,240,240); " +
			"$check.ForeColor = [System.Drawing.Color]::FromArgb(34,34,34); " +

			"$labelOption = New-Object System.Windows.Forms.Label; " +
			"$labelOption.Text = [string]$option; " +
			"$labelOption.Left = 30; " +
			"$labelOption.Top = 4; " +
			"$labelOption.Width = $formWidth - 100; " +
			"$labelOption.Height = 22; " +
			"$labelOption.AutoSize = $false; " +
			"$labelOption.AutoEllipsis = $false; " +
			"$labelOption.TextAlign = 'MiddleLeft'; " +
			"$labelOption.BackColor = [System.Drawing.Color]::FromArgb(240,240,240); " +
			"$labelOption.ForeColor = [System.Drawing.Color]::FromArgb(34,34,34); " +

			"$row.Controls.Add($check); " +
			"$row.Controls.Add($labelOption); " +
			"$panel.Controls.Add($row); " +

			"$checks += @{ Check = $check; Text = [string]$option }; " +

			"$currentTop += $rowHeight + $spacing; " +
			"} " +

			"$graphics.Dispose(); " +

			"$maxPanelHeight = 365; " +
			"$desiredPanelHeight = $currentTop + 5; " +
			"$panelHeight = [Math]::Min($desiredPanelHeight, $maxPanelHeight); " +
			"$panel.Height = $panelHeight; " +

			"$buttonTop = 60 + $panelHeight; " +
			"$buttonLeft = [int](($formWidth - 200) / 2); " +

			"$ok = New-Object System.Windows.Forms.Button; " +
			"$ok.Text = 'Ok'; " +
			"$ok.Left = $buttonLeft; " +
			"$ok.Top = $buttonTop; " +
			"$ok.Width = 90; " +
			"$ok.Height = 30; " +
			"$ok.FlatStyle = 'Flat'; " +
			"$ok.BackColor = [System.Drawing.Color]::FromArgb(229,229,229); " +
			"$ok.ForeColor = [System.Drawing.Color]::FromArgb(34,34,34); " +
			"$ok.UseVisualStyleBackColor = $false; " +

			"$ok.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(216,216,216) }); " +
			"$ok.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(229,229,229) }); " +
			"$ok.Add_MouseDown({ $this.BackColor = [System.Drawing.Color]::FromArgb(204,204,204) }); " +
			"$ok.Add_MouseUp({ $this.BackColor = [System.Drawing.Color]::FromArgb(216,216,216) }); " +

			"$ok.Add_Click({ " +
			"$result = @(); " +
			"foreach ($item in $checks) { " +
			"if ($item.Check.Checked) { $result += $item.Text; } " +
			"} " +

			"$json = ConvertTo-Json -InputObject ([object[]]$result) -Compress; " +
			"[System.IO.File]::WriteAllText($save, $json); " +
			"$form.Tag = 'confirmed'; " +
			"$form.Close(); " +
			"}); " +

			"$form.Controls.Add($ok); " +

			"$cancel = New-Object System.Windows.Forms.Button; " +
			"$cancel.Text = 'Cancel'; " +
			"$cancel.Left = $buttonLeft + 100; " +
			"$cancel.Top = $buttonTop; " +
			"$cancel.Width = 90; " +
			"$cancel.Height = 30; " +
			"$cancel.FlatStyle = 'Flat'; " +
			"$cancel.BackColor = [System.Drawing.Color]::FromArgb(229,229,229); " +
			"$cancel.ForeColor = [System.Drawing.Color]::FromArgb(34,34,34); " +
			"$cancel.UseVisualStyleBackColor = $false; " +

			"$cancel.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(216,216,216) }); " +
			"$cancel.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(229,229,229) }); " +
			"$cancel.Add_MouseDown({ $this.BackColor = [System.Drawing.Color]::FromArgb(204,204,204) }); " +
			"$cancel.Add_MouseUp({ $this.BackColor = [System.Drawing.Color]::FromArgb(216,216,216) }); " +

			"$cancel.Add_Click({ $form.Close(); }); " +

			"$form.Controls.Add($cancel); " +

			"$form.Height = $buttonTop + 75; " +

			"$form.Add_FormClosed({ " +
			"if ($form.Tag -ne 'confirmed') { " +
			"[System.IO.File]::WriteAllText($save, 'CANCEL'); " +
			"} " +
			"}); " +

			"[void]$form.ShowDialog(); " +
			"\"";

		Krom.sysCommand(psCommand);

		var bytes = Krom.loadBlob("multichoice.txt");

		var confirmed = false;

		if (bytes != null) {

			var result = haxe.io.Bytes.ofData(bytes).toString();

			if (result != "CANCEL") {

				confirmed = true;

				var parsed:Dynamic = haxe.Json.parse(result);

				for (value in (cast parsed:Array<Dynamic>)) {
					selected.push(Std.string(value));
				}
			}
		}

		if (confirmed && selected.length == 0)
			selected = defaults.copy();

		runOutput(confirmed ? 0 : 1);

		#elseif kha_html5

		var dialog:Dynamic =
			js.Browser.document.createElement("dialog");

		dialog.style.width = "max-content";
		dialog.style.minWidth = "250px";
		dialog.style.maxWidth = "90vw";
		dialog.style.maxHeight = "80vh";
		dialog.style.overflowY = "auto";
		dialog.style.boxSizing = "border-box";

		dialog.style.border = "1px solid #aaa";
		dialog.style.borderRadius = "8px";
		dialog.style.padding = "20px";
		dialog.style.background = "#f0f0f0";
		dialog.style.color = "#222";
		dialog.style.fontFamily = "Arial";
		dialog.style.boxShadow = "0 5px 25px #0005";

		dialog.style.marginTop = "60px";
		dialog.style.marginLeft = "auto";
		dialog.style.marginRight = "auto";
		dialog.style.marginBottom = "auto";

		var title = js.Browser.document.createElement("p");

		title.textContent = msg;
		title.style.marginTop = "0";
		title.style.marginBottom = "15px";
		title.style.whiteSpace = "normal";
		title.style.overflowWrap = "anywhere";

		dialog.appendChild(title);

		var checkboxes:Array<Dynamic> = [];

		var finished = false;

		var finish = function(confirm:Bool) {

			if (finished) return;
			finished = true;

			selected = [];

			if (confirm) {

				for (i in 0...checkboxes.length) {
					if (checkboxes[i].checked == true)
						selected.push(options[i]);
				}

				if (selected.length == 0)
					selected = defaults.copy();
			}

			dialog.close();

			js.Browser.document.body.removeChild(dialog);

			js.Browser.window.requestAnimationFrame(function(_) {

				js.Browser.window.requestAnimationFrame(function(_) {

					runOutput(confirm ? 0 : 1);

				});

			});
		};

		for (i in 0...options.length) {

			var index = i;

			var container:Dynamic =
				js.Browser.document.createElement("label");

			container.style.display = "flex";
			container.style.alignItems = "center";
			container.style.width = "100%";
			container.style.boxSizing = "border-box";
			container.style.marginTop = "7px";
			container.style.padding = "8px";
			container.style.background = "#e5e5e5";
			container.style.color = "#222";
			container.style.border = "1px solid #aaa";
			container.style.borderRadius = "4px";
			container.style.cursor = "pointer";
			container.style.overflowWrap = "anywhere";

			var checkbox:Dynamic =
				js.Browser.document.createElement("input");

			checkbox.type = "checkbox";

			checkbox.style.appearance = "none";
			checkbox.style.webkitAppearance = "none";
			checkbox.style.width = "16px";
			checkbox.style.height = "16px";
			checkbox.style.minWidth = "16px";
			checkbox.style.marginRight = "10px";
			checkbox.style.flexShrink = "0";
			checkbox.style.border = "1px solid #888";
			checkbox.style.borderRadius = "3px";
			checkbox.style.backgroundColor = "#f0f0f0";
			checkbox.style.cursor = "pointer";
			checkbox.style.outline = "none";
			checkbox.style.boxShadow = "none";

			checkbox.onchange = function(_) {

				if (checkbox.checked) {
					checkbox.style.backgroundColor = "#888";
					checkbox.style.border = "1px solid #666";
				}
				else {
					checkbox.style.backgroundColor = "#f0f0f0";
					checkbox.style.border = "1px solid #888";
				}
			};

			var text = js.Browser.document.createElement("span");

			text.textContent = options[index];
			text.style.overflowWrap = "anywhere";

			container.onmouseenter = function(_) {
				container.style.background = "#d8d8d8";
			};

			container.onmouseleave = function(_) {
				container.style.background = "#e5e5e5";
			};

			container.appendChild(checkbox);
			container.appendChild(text);

			dialog.appendChild(container);

			checkboxes.push(checkbox);
		}

		var buttons = js.Browser.document.createElement("div");

		buttons.style.display = "flex";
		buttons.style.justifyContent = "flex-end";
		buttons.style.gap = "8px";
		buttons.style.marginTop = "18px";

		var ok = js.Browser.document.createElement("button");

		ok.textContent = "Ok";
		ok.style.padding = "6px 16px";
		ok.style.boxSizing = "border-box";
		ok.style.background = "#e5e5e5";
		ok.style.color = "#222";
		ok.style.border = "1px solid #aaa";
		ok.style.borderRadius = "4px";
		ok.style.cursor = "pointer";
		ok.style.outline = "none";
		ok.style.boxShadow = "none";

		ok.onmouseenter = function(_) {
			ok.style.background = "#d8d8d8";
		};

		ok.onmouseleave = function(_) {
			ok.style.background = "#e5e5e5";
		};

		ok.onmousedown = function(_) {
			ok.style.background = "#ccc";
		};

		ok.onmouseup = function(_) {
			ok.style.background = "#d8d8d8";
		};

		ok.onclick = function(_) {
			finish(true);
		};

		var cancel = js.Browser.document.createElement("button");

		cancel.textContent = "Cancel";
		cancel.style.padding = "6px 16px";
		cancel.style.boxSizing = "border-box";
		cancel.style.background = "#e5e5e5";
		cancel.style.color = "#222";
		cancel.style.border = "1px solid #aaa";
		cancel.style.borderRadius = "4px";
		cancel.style.cursor = "pointer";
		cancel.style.outline = "none";
		cancel.style.boxShadow = "none";

		cancel.onmouseenter = function(_) {
			cancel.style.background = "#d8d8d8";
		};

		cancel.onmouseleave = function(_) {
			cancel.style.background = "#e5e5e5";
		};

		cancel.onmousedown = function(_) {
			cancel.style.background = "#ccc";
		};

		cancel.onmouseup = function(_) {
			cancel.style.background = "#d8d8d8";
		};

		cancel.onclick = function(_) {
			finish(false);
		};

		buttons.appendChild(ok);
		buttons.appendChild(cancel);

		dialog.appendChild(buttons);

		dialog.oncancel = function(e) {
			e.preventDefault();
			finish(false);
		};

		js.Browser.document.body.appendChild(dialog);

		dialog.showModal();

		js.Browser.document.activeElement.blur();

		#end
	}

	override function get(from:Int):Dynamic {
		return from == 2 ? selected : selected.length;
	}
}