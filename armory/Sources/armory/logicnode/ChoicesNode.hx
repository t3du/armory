
package armory.logicnode;

class ChoicesNode extends LogicNode {

	var selected:String = "";

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {

		var msg:String = inputs[1].get();
		var options:Array<String> = inputs[2].get();

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

			"$save = '" + escapedSave + "'; " +
			"Remove-Item -LiteralPath $save -ErrorAction SilentlyContinue; " +

			"$form = New-Object System.Windows.Forms.Form; " +
			"$form.Text = '" + Main.projectName + "'; " +
			"$form.Width = 320; " +
			"$form.Height = " + (options.length * 50 + 90) + "; " +
			"$form.StartPosition = 'CenterScreen'; " +

			"$label = New-Object System.Windows.Forms.Label; " +
			"$label.Text = '" + escapedMsg + "'; " +
			"$label.Left = 15; $label.Top = 10; " +
			"$label.Width = 275; $label.Height = 35; " +
			"$form.Controls.Add($label); " +

			"$options = @(" + optionList + "); " +

			"foreach ($option in $options) { " +
			"$btn = New-Object System.Windows.Forms.Button; " +
			"$btn.Text = $option; " +
			"$btn.Width = 260; $btn.Height = 35; " +
			"$btn.Left = 20; " +
			"$btn.Top = 50 + ($form.Controls.Count - 1) * 40; " +
			"$btn.Tag = $option; " +

			"$btn.Add_Click({ " +
			"[System.IO.File]::WriteAllText($save, [string]$this.Tag); " +
			"$form.Close(); " +
			"}); " +

			"$form.Controls.Add($btn); " +
			"}; " +

			"$form.Add_FormClosed({ " +
			"if (!(Test-Path $save)) { " +
			"[System.IO.File]::WriteAllText($save, ''); " +
			"} " +
			"}); " +

			"[void]$form.ShowDialog(); " +
			"\"";

		Krom.sysCommand(psCommand);

		var bytes = Krom.loadBlob("choices.txt");

		if (bytes != null)
			selected = haxe.io.Bytes.ofData(bytes).toString();

		#elseif kha_html5

		var choicesText = "";

		for (i in 0...options.length)
			choicesText += (i + 1) + " : " + options[i] + "\n";

		var result = js.Browser.window.prompt(
			msg + "\n\n" + choicesText,
			"1"
		);

		if (result != null) {
			result = StringTools.trim(result);

			var index = Std.parseInt(result);

			if (index != null && index >= 1 && index <= options.length)
				selected = options[index - 1];
			else
				for (option in options)
					if (result.toLowerCase() == option.toLowerCase()) {
						selected = option;
						break;
					}
		}

		#end

		if (selected != "")
			runOutput(0);
		else
			runOutput(1);
	}

	override function get(from:Int):Dynamic {
		return selected;
	}
}
