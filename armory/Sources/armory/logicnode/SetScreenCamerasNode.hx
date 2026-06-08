package armory.logicnode;

import iron.Scene;
import iron.object.CameraObject;
import armory.renderpath.RenderPathCreator;

class SetScreenCamerasNode extends LogicNode {
    var originalDrawMeshes: Void -> Void;
    var originalCamera: CameraObject;
    var cameras: Array<CameraObject>;
    var viewports: Array<{x:Int, y:Int, w:Int, h:Int}>;

    public function new(tree: LogicTree) {
        super(tree);
    }

    override function run(from: Int) {
        if (from == 0) {
            var numCams = Std.int((inputs.length - 2) / 5);
            cameras = [];
            viewports = [];

            for (i in 0...numCams) {
                var vx = inputs[2 + i * 5 + 1].get();
                var vy = inputs[2 + i * 5 + 2].get();
                var vw = inputs[2 + i * 5 + 3].get();
                var vh = inputs[2 + i * 5 + 4].get();
                viewports.push({x: vx, y: vy, w: vw, h: vh});

                var cam: CameraObject = inputs[2 + i * 5].get();
                cam.buildProjection(vw / vh);
                cameras.push(cam);
            }

            if (originalDrawMeshes == null) {
                originalCamera = Scene.active.camera;
                originalDrawMeshes = RenderPathCreator.drawMeshes;

                RenderPathCreator.drawMeshes = function() {
                    var g = RenderPathCreator.path.currentG;
                    for (i in 0...cameras.length) {
                        RenderPathCreator.setTargetMeshes();
                        Scene.active.camera = cameras[i];
                        g.viewport(viewports[i].x, viewports[i].y, viewports[i].w, viewports[i].h);
                        originalDrawMeshes();
                    }
                };
            }

            runOutput(0);

        } else {
            if (originalDrawMeshes != null) {
                RenderPathCreator.drawMeshes = originalDrawMeshes;
                originalDrawMeshes = null;
                Scene.active.camera = originalCamera;
                originalCamera = null;
                Scene.active.camera.buildProjection();
            }

            runOutput(1);
        }
    }
}