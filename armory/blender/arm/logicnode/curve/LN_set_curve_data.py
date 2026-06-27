from arm.logicnode.arm_nodes import *

class SetCurveDataNode(ArmLogicTreeNode):
    """Sets curve data."""
    bl_idname = 'LNSetCurveDataNode'
    bl_label = 'Set Curve Data'
    arm_section = 'Curve'
    arm_version = 1

    def update_sockets(self, context):
        self.inputs.clear()
        self.outputs.clear()
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Curve')
        self.add_output('ArmNodeSocketAction', 'Out')
        if self.property0 == 'Equidistant Samples':
            self.add_input('ArmIntSocket', 'Samples')
        elif self.property0 == 'Strength':
            self.add_input('ArmFloatSocket', 'Strength')
        elif self.property0 == 'Color':
            self.add_input('ArmColorSocket', 'Color')

    property0: HaxeEnumProperty(
        'property0',
        items = [('Equidistant Samples', 'Equidistant Samples', 'Equidistant Samples'),
                 ('Strength', 'Strength', 'Strength'),
                 ('Color', 'Color', 'Color')],
        name='', default='Equidistant Samples', update=update_sockets)

    def arm_init(self, context):
        self.update_sockets(context)

    def draw_buttons(self, context, layout):
        layout.prop(self, 'property0')