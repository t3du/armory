from arm.logicnode.arm_nodes import *

class SetCurveDataNode(ArmLogicTreeNode):
    """Sets curve data."""
    bl_idname = 'LNSetCurveDataNode'
    bl_label = 'Set Curve Data'
    arm_section = 'set'
    arm_version = 1

    def update_sockets(self, context):
        while len(self.inputs) > 2:
            self.inputs.remove(self.inputs[-1])
        if self.property0 == 'Equidistant Samples':
            self.add_input('ArmIntSocket', 'Equidistant Samples')
        elif self.property0 == 'Strength':
            self.add_input('ArmFloatSocket', 'Strength')
        elif self.property0 == 'Color':
            self.add_input('ArmColorSocket', 'Color')
        else:
            self.add_input('ArmIntSocket', 'Resolution', default_value = 12)

    property0: HaxeEnumProperty(
        'property0',
        items = [('Equidistant Samples', 'Equidistant Samples', 'Equidistant Samples'),
                 ('Resolution', 'Resolution', 'Resolution'),
                 ('Strength', 'Strength', 'Strength'),
                 ('Color', 'Color', 'Color')],
        name='', default='Equidistant Samples', update=update_sockets)

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Curve')
        self.add_input('ArmIntSocket', 'Equidistant Samples')

        self.add_output('ArmNodeSocketAction', 'Out')

    def draw_buttons(self, context, layout):
        layout.prop(self, 'property0')