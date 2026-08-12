from arm.logicnode.arm_nodes import *

class SetCurveDataNode(ArmLogicTreeNode):
    """Sets curve data."""
    bl_idname = 'LNSetCurveDataNode'
    bl_label = 'Set Curve Data'
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
        elif self.property0 == 'Curve Mesh Bevel':
            self.add_input('ArmFloatSocket', 'Depth', default_value = 0.1)
            self.add_input('ArmIntSocket', 'Resolution')
            self.add_input('ArmFloatSocket', 'Start')
            self.add_input('ArmFloatSocket', 'End', default_value = 1.0)
            self.add_input('ArmBoolSocket', 'Fill Caps')
        elif self.property0 == 'Curve Mesh Extrude':
            self.add_input('ArmFloatSocket', 'Width', default_value = 0.1)
            self.add_input('ArmFloatSocket', 'Thickness')
            self.add_input('ArmFloatSocket', 'Start')
            self.add_input('ArmFloatSocket', 'End', default_value = 1.0)
            self.add_input('ArmBoolSocket', 'Fill Caps')

    property0: HaxeEnumProperty(
        'property0',
        items = [('Equidistant Samples', 'Equidistant Samples', 'Equidistant Samples'),
                 ('Strength', 'Strength', 'Strength'),
                 ('Color', 'Color', 'Color'),
                 ('Curve Mesh Bevel', 'Curve Mesh Bevel', 'Curve Mesh Bevel'),
                 ('Curve Mesh Extrude', 'Curve Mesh Extrude', 'Curve Mesh Extrude')],
        name='', default='Equidistant Samples', update=update_sockets)

    def arm_init(self, context):
        self.update_sockets(context)

    def draw_buttons(self, context, layout):
        layout.prop(self, 'property0')