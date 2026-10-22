package armory.logicnode;

class OpenFileNode extends LogicNode {

	public var nameStr: String = "";
	public var content: String = "";

	public function new(tree:LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		var ext: String = inputs[1].get();

		#if kha_krom
		var save = Krom.getFilesLocation() + "/path.txt";
		var psCommand = "powershell -command \"Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.OpenFileDialog;";
		if (ext != null && ext != "") {
			psCommand += " $f.Filter = 'Files (*." + ext + ")|*." + ext + "|All files (*.*)|*.*';";
		}
		psCommand += " if($f.ShowDialog() -eq 'OK'){[System.IO.File]::WriteAllText('" + save + "', $f.FileName)}\"";
		Krom.sysCommand(psCommand);
		
		var pathBytes = Krom.loadBlob("path.txt");
		if (pathBytes != null) {
			var path = haxe.io.Bytes.ofData(pathBytes).toString();
			if (path != "") {
				nameStr = path.substr(path.lastIndexOf("\\") + 1);
				if (nameStr == "") nameStr = path.substr(path.lastIndexOf("/") + 1);
				
				var fileBytes = Krom.loadBlob(path);
				if (fileBytes != null) {
					content = haxe.io.Bytes.ofData(fileBytes).toString();
				}
			}
		}
		runOutput(0);
		#elseif kha_html5
		var self = this;
		js.Syntax.code("
			var input = document.createElement('input');
			input.type = 'file';
			var ext = {1};
			if (ext) {
				input.accept = '.' + ext;
			}
			input.onchange = function(e) {
				var file = e.target.files[0];
				if (file) {
					{0}.nameStr = file.name;
					var reader = new FileReader();
					reader.onload = function(evt) {
						{0}.content = evt.target.result;
						{0}.runOutput(0);
					};
					reader.readAsText(file);
				}
			};
			input.click();
		", self, ext);
		#end
	}

	override function get(from: Int): Dynamic {
		return from == 1 ? nameStr : content;
	}
}