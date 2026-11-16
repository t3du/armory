from arm.logicnode.arm_nodes import *


class TranslateRenderTargetNode(ArmLogicTreeNode):
    """Translates (moves) the render target canvas.

    @input In: Activate to translate render target. The input must
        be (indirectly) called from an `On Render2D` node or a draw target node.
    @input X: Horizontal offset in pixels.
    @input Y: Vertical offset in pixels.
    @input Revert After: Revert translation after all connected draw calls
        have executed.

    @output Out: Activated with translation applied. Connect draw nodes here.

    @see [`kha.graphics2.Graphics.translate()`](http://kha.tech/api/kha/graphics2/Graphics.html#translate).
    """
    bl_idname = 'LNTranslateRenderTargetNode'
    bl_label = 'Translate Render Target'
    arm_section = 'draw'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmFloatSocket', 'X')
        self.add_input('ArmFloatSocket', 'Y')
        self.add_input('ArmBoolSocket', 'Revert after', default_value=True)

        self.add_output('ArmNodeSocketAction', 'Out')
