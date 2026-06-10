from arm.logicnode.arm_nodes import *

class DrawCameraNode(ArmLogicTreeNode):
    """Renders the scene from the view of specified cameras and draws
    the render targets to the screen.

    @input Start: Evaluate the inputs and start drawing the camera render targets.
    @input Stop: Stops the rendering and drawing of the camera render targets.
    @input Camera: The camera from which to render.
    @input X/Y: Position where the camera's render target is drawn, in pixels from the top left corner.
    @input Width/Height: Size of the camera's render target in pixels.

    @output On Start: Activated after the `Start` input has been activated.
    @output On Stop: Activated after the `Stop` input has been activated.
    """
    bl_idname = 'LNDrawCameraNode'
    bl_label = 'Draw Camera'
    arm_section = 'draw'
    arm_version = 4

    num_choices: IntProperty(default=0, min=0)

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'Start')
        self.add_input('ArmNodeSocketAction', 'Stop')
        self.add_input('ArmNodeSocketObject', 'Camera ' + str(self.num_choices))
        self.add_input('ArmIntSocket', 'X')
        self.add_input('ArmIntSocket', 'Y')
        self.add_input('ArmIntSocket', 'Width')
        self.add_input('ArmIntSocket', 'Height')
        self.add_input('ArmBoolSocket', 'Paused')

        self.add_output('ArmNodeSocketAction', 'On Start')
        self.add_output('ArmNodeSocketAction', 'On Stop')

    def get_replacement_node(self, node_tree: bpy.types.NodeTree):
        if self.arm_version not in (0, 1):
            raise LookupError()
            
        return NodeReplacement.Identity(self)
