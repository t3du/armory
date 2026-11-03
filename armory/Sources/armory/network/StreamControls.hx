
package armory.network;

import js.Browser;

class StreamControls {

	var stream:Dynamic;
	var video:Dynamic;
	var audio:Dynamic;

	var videoWindow:Dynamic;
	var videoClip:Dynamic;
	var videoControls:Dynamic;

	var audioButton:Dynamic;
	var videoButton:Dynamic;
	var fullscreenButton:Dynamic;

	var audioEnabled:Bool;
	var videoVisible:Bool;

	var disposed:Bool = false;
	var isFullscreen:Bool = false;

	var originalFullscreenStyle:Dynamic = null;

	var previousWindowHeight:Dynamic = null;
	var previousWindowWidth:Dynamic = null;

	static var windowZIndex = 12000;

	var title:String;
	var x:Int;
	var y:Int;
	var width:Int;
	var height:Int;

	var panelStyle:String;
	var buttonStyle:String;
	var videoStyle:String;

	static var defaultPanelStyle =
		"background:rgba(35,39,47,.97);" +
		"border:1px solid #41444b;" +
		"border-radius:12px;" +
		"padding:10px;" +
		"gap:8px;" +
		"box-shadow:0 8px 24px rgba(0,0,0,.4);" +
		"font:13px sans-serif;";

	static var defaultButtonStyle =
		"padding:9px 13px;" +
		"background:#404249;" +
		"color:#ffffff;" +
		"border:0;" +
		"border-radius:7px;" +
		"font:500 13px sans-serif;" +
		"cursor:pointer;" +
		"transition:filter .15s ease;" +
		"outline:none;";

	static var defaultVideoStyle =
		"background:#18191c;" +
		"border:1px solid #41444b;" +
		"border-radius:12px;" +
		"box-shadow:0 8px 24px rgba(0,0,0,.4);" +
		"box-sizing:border-box;";

	public function new(
		stream:Dynamic,
		title:String,
		x:Int,
		y:Int,
		width:Int,
		height:Int,
		videoVisible:Bool,
		audioEnabled:Bool,
		panelStyle:String,
		buttonStyle:String,
		videoStyle:String
	) {

		this.stream = stream;
		this.title = title;

		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;

		this.videoVisible = videoVisible;
		this.audioEnabled = audioEnabled;

		this.panelStyle =
			panelStyle == null || panelStyle == ""
			? defaultPanelStyle : panelStyle;

		this.buttonStyle =
			buttonStyle == null || buttonStyle == ""
			? defaultButtonStyle : buttonStyle;

		this.videoStyle =
			videoStyle == null || videoStyle == ""
			? defaultVideoStyle : videoStyle;
	}

	public function create():Void {

		if (disposed || stream == null)
			return;

		try {

			var audioTracks:Dynamic = stream.getAudioTracks();
			var videoTracks:Dynamic = stream.getVideoTracks();

			if (audioTracks.length == 0 && videoTracks.length == 0) {
				trace("StreamControls: Media Stream has no tracks.");
				return;
			}

			if (audioTracks.length > 0)
				setupAudio(audioTracks);

			if (videoTracks.length > 0)
				setupVideo();

		}
		catch (error:Dynamic) {

			trace("StreamControls: " + Std.string(error));
			dispose();
		}
	}

	function addControl(
		label:String,
		onClick:Dynamic->Void
	):Dynamic {

		var button:Dynamic =
			Browser.document.createElement("button");

		button.type = "button";
		button.textContent = label;
		button.style.cssText = buttonStyle;

		button.onmouseenter = function(_event:Dynamic) {
			button.style.filter = "brightness(1.2)";
		};

		button.onmouseleave = function(_event:Dynamic) {
			button.style.filter = "none";
		};

		button.onclick = onClick;

		return button;
	}

	function setButtonIcon(
		button:Dynamic,
		icon:String,
		label:String
	):Void {

		if (button == null) return;

		var paths:Map<String, String> = [

			"mic" =>
				'<rect x="9" y="2" width="6" height="12" rx="3"/>' +
				'<path d="M5 10v2a7 7 0 0 0 14 0v-2"/>' +
				'<line x1="12" y1="19" x2="12" y2="23"/>' +
				'<line x1="8" y1="23" x2="16" y2="23"/>',

			"mic-off" =>
				'<line x1="2" y1="2" x2="22" y2="22"/>' +
				'<path d="M9 9v3a3 3 0 0 0 5.12 2.12"/>' +
				'<path d="M15 9.34V5a3 3 0 0 0-5.94-.6"/>' +
				'<path d="M17 16.95A7 7 0 0 1 5 12v-2"/>' +
				'<path d="M19 10v2a7 7 0 0 1-.35 2.2"/>' +
				'<line x1="12" y1="19" x2="12" y2="23"/>' +
				'<line x1="8" y1="23" x2="16" y2="23"/>',

			"video" =>
				'<rect x="3" y="5" width="13" height="14" rx="2"/>' +
				'<path d="m16 10 5-3v10l-5-3z"/>',

			"video-off" =>
				'<path d="M15 10l6-3v10l-6-3"/>' +
				'<rect x="3" y="5" width="13" height="14" rx="2"/>' +
				'<line x1="2" y1="2" x2="22" y2="22"/>',

			"maximize" =>
				'<path d="M8 3H5a2 2 0 0 0-2 2v3"/>' +
				'<path d="M16 3h3a2 2 0 0 1 2 2v3"/>' +
				'<path d="M8 21H5a2 2 0 0 1-2-2v-3"/>' +
				'<path d="M16 21h3a2 2 0 0 0 2-2v-3"/>',

			"minimize" =>
				'<path d="M8 3v3a2 2 0 0 1-2 2H3"/>' +
				'<path d="M21 8h-3a2 2 0 0 1-2-2V3"/>' +
				'<path d="M3 16h3a2 2 0 0 1 2 2v3"/>' +
				'<path d="M16 21v-3a2 2 0 0 1 2-2h3"/>'
		];

		var svg:Dynamic =
			Browser.document.createElementNS(
				"http://www.w3.org/2000/svg",
				"svg"
			);

		svg.setAttribute("width", "20");
		svg.setAttribute("height", "20");
		svg.setAttribute("viewBox", "0 0 24 24");
		svg.setAttribute("fill", "none");
		svg.setAttribute("stroke", "currentColor");
		svg.setAttribute("stroke-width", "2");
		svg.setAttribute("stroke-linecap", "round");
		svg.setAttribute("stroke-linejoin", "round");

		svg.innerHTML = paths.get(icon);

		button.innerHTML = "";
		button.appendChild(svg);

		button.title = label;
		button.setAttribute("aria-label", label);

		button.style.display = "flex";
		button.style.alignItems = "center";
		button.style.justifyContent = "center";
		button.style.width = "44px";
		button.style.height = "44px";
		button.style.padding = "0";
		button.style.borderRadius = "50%";
		button.style.flex = "0 0 44px";
	}

	function setupAudio(tracks:Dynamic):Void {

		audio = Browser.document.createElement("audio");

		audio.autoplay = true;
		audio.playsInline = true;
		audio.muted = !audioEnabled;
		audio.style.display = "none";

		audio.srcObject =
			js.Syntax.code("new MediaStream({0})", tracks);

		Browser.document.body.appendChild(audio);

		audio.play().then(null, function(error:Dynamic) {

			if (!disposed)
				trace("StreamControls: Audio playback failed: " +
					Std.string(error));
		});
	}

	function setupVideo():Void {

		video = Browser.document.createElement("video");

		video.autoplay = true;
		video.muted = true;
		video.playsInline = true;
		video.srcObject = stream;

		videoWindow = createVideoWindow(video);

		videoClip.style.display =
			videoVisible ? "block" : "none";

		if (!videoVisible) {
			videoWindow.style.height = "auto";
			videoWindow.style.minHeight = "0";
			videoWindow.style.resize = "none";
		}

		videoButton = addControl("", function(_event:Dynamic) {

			toggleVideo();
		});

		setButtonIcon(
			videoButton,
			videoVisible ? "video" : "video-off",
			videoVisible ? "Hide video" : "Show video"
		);

		audioButton = addControl("", function(_event:Dynamic) {

			toggleAudio();
		});

		setButtonIcon(
			audioButton,
			audioEnabled ? "mic" : "mic-off",
			audioEnabled ? "Mute audio" : "Unmute audio"
		);

		fullscreenButton = addControl("", function(_event:Dynamic) {

			toggleFullscreen();
		});

		setButtonIcon(fullscreenButton, "maximize", "Fullscreen");

		videoControls.appendChild(videoButton);
		videoControls.appendChild(audioButton);
		videoControls.appendChild(fullscreenButton);

		video.play().then(null, function(error:Dynamic) {

			if (!disposed)
				trace("StreamControls: Video playback failed: " +
					Std.string(error));
		});
	}

	function toggleVideo():Void {

		videoVisible = !videoVisible;

		if (!videoVisible) {

			if (!isFullscreen) {

				previousWindowHeight = videoWindow.style.height;
				previousWindowWidth = videoWindow.style.width;
			}

			videoClip.style.display = "none";

			if (!isFullscreen) {

				videoWindow.style.height = "auto";
				videoWindow.style.minHeight = "0";
				videoWindow.style.resize = "none";
			}
		}
		else {

			videoClip.style.display = "block";

			if (!isFullscreen) {

				videoWindow.style.height = previousWindowHeight;
				videoWindow.style.width = previousWindowWidth;

				videoWindow.style.minHeight = "120px";
				videoWindow.style.resize = "both";
			}
		}

		updateControls();
	}

	function toggleAudio():Void {

		audioEnabled = !audioEnabled;

		if (audio != null)
			audio.muted = !audioEnabled;

		updateControls();
	}

	function toggleFullscreen():Void {

		if (videoWindow == null || disposed)
			return;

		if (!isFullscreen) {

			originalFullscreenStyle = {
				left: videoWindow.style.left,
				top: videoWindow.style.top,
				width: videoWindow.style.width,
				height: videoWindow.style.height,
				zIndex: videoWindow.style.zIndex,
				borderRadius: videoWindow.style.borderRadius,
				minHeight: videoWindow.style.minHeight,
				resize: videoWindow.style.resize
			};

			isFullscreen = true;

			videoWindow.style.position = "fixed";
			videoWindow.style.left = "0";
			videoWindow.style.top = "0";
			videoWindow.style.width = "100vw";
			videoWindow.style.height = "100vh";
			videoWindow.style.minWidth = "0";
			videoWindow.style.minHeight = "0";
			videoWindow.style.borderRadius = "0";
			videoWindow.style.resize = "none";
			videoWindow.style.zIndex = "2147483647";

		}
		else {

			restoreVideoWindow();
		}

		updateControls();
	}

	function restoreVideoWindow():Void {

		if (!isFullscreen || videoWindow == null)
			return;

		if (originalFullscreenStyle != null) {

			videoWindow.style.position = "fixed";
			videoWindow.style.left = originalFullscreenStyle.left;
			videoWindow.style.top = originalFullscreenStyle.top;
			videoWindow.style.width = originalFullscreenStyle.width;
			videoWindow.style.height = originalFullscreenStyle.height;
			videoWindow.style.zIndex = originalFullscreenStyle.zIndex;
			videoWindow.style.borderRadius = originalFullscreenStyle.borderRadius;

			videoWindow.style.minWidth = "180px";

			if (videoVisible) {

				videoWindow.style.minHeight = "120px";
				videoWindow.style.resize = "both";
			}
			else {

				videoWindow.style.minHeight = "0";
				videoWindow.style.height = "auto";
				videoWindow.style.resize = "none";
			}
		}

		originalFullscreenStyle = null;
		isFullscreen = false;
	}

	function createVideoWindow(videoElement:Dynamic):Dynamic {

		var doc = Browser.document;

		var container:Dynamic = doc.createElement("div");
		var header:Dynamic = doc.createElement("div");

		container.style.cssText =
			"position:fixed;" +
			"left:" + Std.int(Math.max(0, x)) + "px;" +
			"top:" + Std.int(Math.max(0, y)) + "px;" +
			"width:" + Std.int(Math.max(180, width)) + "px;" +
			"height:" + Std.int(Math.max(120, height)) + "px;" +
			"min-width:180px;" +
			"min-height:120px;" +
			"resize:both;" +
			"display:flex;" +
			"flex-direction:column;" +
			"overflow:hidden;" +
			"z-index:" + windowZIndex++ + ";" +
			videoStyle +
			"box-sizing:border-box;";

		header.textContent = title;

		header.style.cssText =
			"display:flex;" +
			"align-items:center;" +
			"justify-content:center;" +
			"width:100%;" +
			"height:32px;" +
			"min-height:32px;" +
			"box-sizing:border-box;" +
			"background:#23272f;" +
			"color:#f2f3f5;" +
			"font:600 13px sans-serif;" +
			"border-bottom:1px solid #41444b;" +
			"white-space:nowrap;" +
			"overflow:hidden;" +
			"text-overflow:ellipsis;" +
			"cursor:move;" +
			"user-select:none;" +
			"touch-action:none;";

		videoClip = doc.createElement("div");

		videoClip.style.cssText =
			"display:block;" +
			"position:relative;" +
			"flex:1 1 auto;" +
			"min-height:0;" +
			"width:100%;" +
			"overflow:hidden;" +
			"box-sizing:border-box;";

		videoElement.style.cssText =
			"display:block;" +
			"width:100%;" +
			"height:100%;" +
			"object-fit:contain;" +
			"background:#18191c;" +
			"border:0;" +
			"box-sizing:border-box;";

		videoClip.appendChild(videoElement);

		videoControls = doc.createElement("div");

		videoControls.style.cssText =
			"display:flex;" +
			"flex:0 0 auto;" +
			"flex-direction:row;" +
			"align-items:center;" +
			"justify-content:center;" +
			"gap:12px;" +
			"width:100%;" +
			"padding:9px;" +
			"background:#23272f;" +
			"border-top:1px solid #41444b;" +
			"box-sizing:border-box;";

		container.appendChild(header);
		container.appendChild(videoClip);
		container.appendChild(videoControls);

		doc.body.appendChild(container);

		var dragging = false;
		var pointerId = -1;

		var startX = 0.0;
		var startY = 0.0;
		var startLeft = 0.0;
		var startTop = 0.0;

		header.onpointerdown = function(event:Dynamic) {

			if (event.button != 0 || isFullscreen) return;

			event.preventDefault();

			var rect:Dynamic = container.getBoundingClientRect();

			dragging = true;
			pointerId = event.pointerId;

			startX = event.clientX;
			startY = event.clientY;

			startLeft = rect.left;
			startTop = rect.top;

			header.setPointerCapture(pointerId);

			container.style.zIndex = Std.string(windowZIndex++);
		};

		header.onpointermove = function(event:Dynamic) {

			if (!dragging || event.pointerId != pointerId)
				return;

			container.style.left =
				Std.string(Math.max(0,
					startLeft + event.clientX - startX)) + "px";

			container.style.top =
				Std.string(Math.max(0,
					startTop + event.clientY - startY)) + "px";
		};

		header.onpointerup = function(event:Dynamic) {

			if (event.pointerId == pointerId)
				dragging = false;
		};

		header.onpointercancel = function(_event:Dynamic) {
			dragging = false;
		};

		return container;
	}

	function updateControls():Void {

		if (audioButton != null) {

			setButtonIcon(
				audioButton,
				audioEnabled ? "mic" : "mic-off",
				audioEnabled ? "Mute audio" : "Unmute audio"
			);
		}

		if (videoButton != null) {

			setButtonIcon(
				videoButton,
				videoVisible ? "video" : "video-off",
				videoVisible ? "Hide video" : "Show video"
			);
		}

		if (fullscreenButton != null) {

			setButtonIcon(
				fullscreenButton,
				isFullscreen ? "minimize" : "maximize",
				isFullscreen ? "Restore size" : "Fullscreen"
			);
		}
	}

	public function dispose():Void {

		if (disposed) return;

		disposed = true;

		if (isFullscreen)
			restoreVideoWindow();

		if (video != null) {

			video.pause();
			video.srcObject = null;
		}

		if (audio != null) {

			audio.pause();
			audio.srcObject = null;
			audio.remove();
		}

		if (videoWindow != null) {

			videoWindow.remove();
			videoWindow = null;
		}

		stream = null;
		video = null;
		audio = null;

		videoClip = null;
		videoControls = null;

		audioButton = null;
		videoButton = null;
		fullscreenButton = null;

		originalFullscreenStyle = null;
		previousWindowHeight = null;
		previousWindowWidth = null;

		isFullscreen = false;
	}
}