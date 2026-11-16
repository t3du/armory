from arm.logicnode.arm_nodes import *


class BlendRenderTargetNode(ArmLogicTreeNode):
    """Sets the blending mode for subsequent render target draw operations.
    Connect between a draw target node (such as `Draw To Screen` or `Draw To Material Image`)
    and the draw nodes to control how pixels combine with existing ones.

    @input In: Activate to apply the blend mode. The input must
        be (indirectly) called from an `On Render2D` node or a draw target node.
    @input Revert After: Revert to standard alpha blending after all connected
        draw calls have executed.

    @output Out: Activated with the blend mode active. Connect draw nodes here.

    @see [`kha.graphics4.BlendingOperation`](http://kha.tech/api/kha/graphics4/BlendingOperation.html).
    @see [`kha.graphics4.BlendingFactor`](http://kha.tech/api/kha/graphics4/BlendingFactor.html).
    """
    bl_idname = 'LNBlendRenderTargetNode'
    bl_label = 'Blend Render Target'
    arm_section = 'draw'
    arm_version = 1

    property0: HaxeEnumProperty(
        'property0',
        items=[('Normal', 'Normal', 'Standard alpha blending'),
               ('Erase', 'Erase', 'Erases destination where drawn'),
               ('Additive', 'Additive', 'Adds color to destination'),
               ('Multiply', 'Multiply', 'Multiplies colors together')],
        name='', default='Normal')

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmBoolSocket', 'Revert after', default_value=True)

        self.add_output('ArmNodeSocketAction', 'Out')

    def draw_buttons(self, context, layout):
        layout.prop(self, 'property0')
