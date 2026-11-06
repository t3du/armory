package armory.logicnode;

class OpenFileNode extends LogicNode {

	public var nameStr: String = "";
	public var content: Dynamic = null;

	public function new(tree: LogicTree) {
		super(tree);
	}

	override function run(from: Int) {
		// Allowed file extension
		var ext: String = inputs[1].get();

		#if kha_krom

		// Open file dialog
		var save = Krom.getFilesLocation() + "/path.txt";

		var psCommand = "powershell -command \"Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.OpenFileDialog;";

		if (ext != null && ext != "") {
			psCommand += " $f.Filter = 'Files (*." + ext + ")|*." + ext + "|All files (*.*)|*.*';";
		}

		psCommand += " if($f.ShowDialog() -eq 'OK'){[System.IO.File]::WriteAllText('" + save + "', $f.FileName)}\"";

		Krom.sysCommand(psCommand);

		// Read selected file path
		var pathBytes = Krom.loadBlob("path.txt");

		if (pathBytes != null) {
			var path = haxe.io.Bytes.ofData(pathBytes).toString();

			if (path != "") {
				// Extract file name
				nameStr = path.substr(path.lastIndexOf("\\") + 1);

				if (nameStr == "") {
					nameStr = path.substr(path.lastIndexOf("/") + 1);
				}

				// Read file as binary data
				var fileBytes = Krom.loadBlob(path);

				if (fileBytes != null) {
					content = haxe.io.Bytes.ofData(fileBytes);
				}
			}
		}

		runOutput(0);

		#elseif kha_html5

		// Create browser file input
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

					// Read file as binary data
					var reader = new FileReader();

					reader.onload = function(evt) {
						{0}.content = evt.target.result;
						{0}.runOutput(0);
					};

					reader.onerror = function() {
						console.error('Error reading file:', reader.error);
					};

					reader.readAsArrayBuffer(file);
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
