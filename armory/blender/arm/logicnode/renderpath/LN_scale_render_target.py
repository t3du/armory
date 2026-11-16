from arm.logicnode.arm_nodes import *


class ScaleRenderTargetNode(ArmLogicTreeNode):
    """Scales the render target canvas around a center point.

    @input In: Activate to scale render target. The input must
        be (indirectly) called from an `On Render2D` node or a draw target node.
    @input Scale X: Horizontal scale factor (1.0 = 100%).
    @input Scale Y: Vertical scale factor (1.0 = 100%).
    @input Center X: X coordinate of the anchor point to scale around.
    @input Center Y: Y coordinate of the anchor point to scale around.
    @input Revert After: Revert scale after all connected draw calls
        have executed.

    @output Out: Activated with scale applied. Connect draw nodes here.

    @see [`kha.graphics2.Graphics.scale()`](http://kha.tech/api/kha/graphics2/Graphics.html#scale).
    """
    bl_idname = 'LNScaleRenderTargetNode'
    bl_label = 'Scale Render Target'
    arm_section = 'draw'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmFloatSocket', 'Scale X', default_value=1.0)
        self.add_input('ArmFloatSocket', 'Scale Y', default_value=1.0)
        self.add_input('ArmFloatSocket', 'Center X', default_value=0.0)
        self.add_input('ArmFloatSocket', 'Center Y', default_value=0.0)
        self.add_input('ArmBoolSocket', 'Revert after', default_value=True)

        self.add_output('ArmNodeSocketAction', 'Out')
