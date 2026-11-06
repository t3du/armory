package armory.logicnode;

class ChoiceNode extends LogicNode {

	var options:Array<String>;
	var selected:String;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {

		var msg:String = inputs[1].get();
		options = inputs[2].get();
		selected = "";
	
		#if kha_krom

		var save = Krom.getFilesLocation() + "/choices.txt";

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
			"$form.AutoSize = $false; " +
			"$form.BackColor = [System.Drawing.Color]::FromArgb(240,240,240); " +
			"$form.ForeColor = [System.Drawing.Color]::FromArgb(34,34,34); " +
			"$form.Font = New-Object System.Drawing.Font('Arial', 9); " +

			"$graphics = $form.CreateGraphics(); " +

			"$maxWidth = 0; " +
			"foreach ($option in $options) { " +
			"$size = $graphics.MeasureString([string]$option, $form.Font); " +
			"$maxWidth = [Math]::Max($maxWidth, $size.Width); " +
			"} " +

			"$msgSize = $graphics.MeasureString('" + escapedMsg + "', $form.Font); " +
			"$formWidth = [Math]::Max(320, [int][Math]::Ceiling([Math]::Max($maxWidth, $msgSize.Width)) + 70); " +
			"$form.Width = $formWidth; " +

			"$label = New-Object System.Windows.Forms.Label; " +
			"$label.Text = '" + escapedMsg + "'; " +
			"$label.Left = 15; " +
			"$label.Top = 10; " +
			"$label.Width = $formWidth - 40; " +
			"$label.Height = 35; " +
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

			"$currentTop = 5; " +
			"$buttonHeight = 35; " +
			"$spacing = 5; " +
			"$buttonWidth = $formWidth - 55; " +

			"foreach ($option in $options) { " +

			"$btn = New-Object System.Windows.Forms.Button; " +
			"$btn.Text = [string]$option; " +
			"$btn.Left = 5; " +
			"$btn.Top = $currentTop; " +
			"$btn.Width = $buttonWidth; " +
			"$btn.Height = $buttonHeight; " +
			"$btn.AutoSize = $false; " +
			"$btn.TextAlign = 'MiddleCenter'; " +
			"$btn.UseVisualStyleBackColor = $false; " +
			"$btn.FlatStyle = 'Flat'; " +
			"$btn.BackColor = [System.Drawing.Color]::FromArgb(229,229,229); " +
			"$btn.ForeColor = [System.Drawing.Color]::FromArgb(34,34,34); " +
			"$btn.Tag = [string]$option; " +

			"$btn.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(216,216,216) }); " +
			"$btn.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(229,229,229) }); " +
			"$btn.Add_MouseDown({ $this.BackColor = [System.Drawing.Color]::FromArgb(204,204,204) }); " +
			"$btn.Add_MouseUp({ $this.BackColor = [System.Drawing.Color]::FromArgb(216,216,216) }); " +

			"$btn.Add_Click({ " +
			"[System.IO.File]::WriteAllText($save, [string]$this.Tag); " +
			"$form.Tag = 'selected'; " +
			"$form.Close(); " +
			"}); " +

			"$panel.Controls.Add($btn); " +

			"$currentTop += $buttonHeight + $spacing; " +
			"} " +

			"$graphics.Dispose(); " +

			"$panelHeight = [Math]::Min($currentTop + 5, 400); " +
			"$panel.Height = $panelHeight; " +
			"$form.Height = 50 + $panelHeight + 55; " +

			"$form.Add_FormClosed({ " +
			"if ($form.Tag -ne 'selected') { " +
			"[System.IO.File]::WriteAllText($save, ''); " +
			"} " +
			"}); " +

			"[void]$form.ShowDialog(); " +
			"\"";

		Krom.sysCommand(psCommand);

		var bytes = Krom.loadBlob("choices.txt");

		if (bytes != null)
			selected = haxe.io.Bytes.ofData(bytes).toString();

		runOutput(selected != "" ? 0 : 1);

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

		var finished = false;

		var finish = function(index:Int) {

			if (finished) return;
			finished = true;

			if (index >= 0 && index < options.length)
				selected = options[index];
			else
				selected = "";

			dialog.close();

			js.Browser.document.body.removeChild(dialog);

			js.Browser.window.requestAnimationFrame(function(_) {

				js.Browser.window.requestAnimationFrame(function(_) {

					runOutput(index >= 0 ? 0 : 1);

				});

			});
		};

		for (i in 0...options.length) {

			var index = i;

			var btn = js.Browser.document.createElement("button");

			btn.textContent = options[index];

			btn.style.display = "block";
			btn.style.width = "100%";
			btn.style.maxWidth = "100%";
			btn.style.boxSizing = "border-box";

			btn.style.whiteSpace = "normal";
			btn.style.overflowWrap = "anywhere";
			btn.style.wordBreak = "normal";
			btn.style.textAlign = "center";

			btn.style.outline = "none";
			btn.style.boxShadow = "none";

			btn.style.marginTop = "7px";
			btn.style.padding = "8px";
			btn.style.background = "#e5e5e5";
			btn.style.color = "#222";
			btn.style.border = "1px solid #aaa";
			btn.style.borderRadius = "4px";
			btn.style.cursor = "pointer";

			btn.onmouseenter = function(_) {
				btn.style.background = "#d8d8d8";
			};

			btn.onmouseleave = function(_) {
				btn.style.background = "#e5e5e5";
			};

			btn.onmousedown = function(_) {
				btn.style.background = "#ccc";
			};

			btn.onmouseup = function(_) {
				btn.style.background = "#d8d8d8";
			};

			btn.onclick = function(_) {
				finish(index);
			};

			dialog.appendChild(btn);
		}

		var cancel = js.Browser.document.createElement("button");

		cancel.textContent = "Cancel";
		cancel.style.display = "block";
		cancel.style.marginTop = "18px";
		cancel.style.marginLeft = "auto";
		cancel.style.padding = "6px 16px";
		cancel.style.boxSizing = "border-box";
		cancel.style.outline = "none";
		cancel.style.boxShadow = "none";
		cancel.style.background = "#e5e5e5";
		cancel.style.color = "#222";
		cancel.style.border = "1px solid #aaa";
		cancel.style.borderRadius = "4px";
		cancel.style.cursor = "pointer";

		cancel.onmouseenter = function(_) {
			cancel.style.background = "#d8d8d8";
		};

		cancel.onmouseleave = function(_) {
			cancel.style.background = "#e5e5e5";
		};

		cancel.onclick = function(_) {
			finish(-1);
		};

		dialog.appendChild(cancel);

		dialog.oncancel = function(e) {
			e.preventDefault();
			finish(-1);
		};

		js.Browser.document.body.appendChild(dialog);

		dialog.showModal();

		js.Browser.document.activeElement.blur();

	#end
	}

	override function get(from:Int):Dynamic {
		return from == 2 ? selected : options.indexOf(selected);
	}
}