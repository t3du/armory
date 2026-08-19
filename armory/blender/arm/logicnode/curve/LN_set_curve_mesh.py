from arm.logicnode.arm_nodes import *

class SetCurveMeshNode(ArmLogicTreeNode):
    """Sets curve mesh."""
    bl_idname = 'LNSetCurveMeshNode'
    bl_label = 'Set Curve Mesh'
    arm_section = 'set'
    arm_version = 1

    def update_sockets(self, context):
        while len(self.inputs) > 2:
            self.inputs.remove(self.inputs[-1])
        if self.property0 == 'Extrude':
            self.add_input('ArmFloatSocket', 'Width', default_value = 0.1)
            self.add_input('ArmFloatSocket', 'Thickness')
            self.add_input('ArmFloatSocket', 'Start')
            self.add_input('ArmFloatSocket', 'End', default_value = 1.0)
            self.add_input('ArmBoolSocket', 'Fill Caps')
        elif self.property0 == 'Bevel':
            self.add_input('ArmFloatSocket', 'Depth', default_value = 0.1)
            self.add_input('ArmIntSocket', 'Resolution')
            self.add_input('ArmFloatSocket', 'Start')
            self.add_input('ArmFloatSocket', 'End', default_value = 1.0)
            self.add_input('ArmBoolSocket', 'Fill Caps')
        else:
            self.add_input('ArmNodeSocketObject', 'Object')
            self.add_input('ArmStringSocket', 'Forward Axis', default_value = 'X')
            self.add_input('ArmIntSocket', 'Repetitions', default_value = 1)
            self.add_input('ArmFloatSocket', 'Start')
            self.add_input('ArmFloatSocket', 'End', default_value = 1.0)

    property0: HaxeEnumProperty(
        'property0',
        items = [('Extrude', 'Extrude', 'Extrude'),
                 ('Bevel', 'Bevel', 'Bevel'),
                 ('Deform', 'Deform', 'Deform')],
        name='', default='Extrude', update=update_sockets)

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Curve')
        self.add_input('ArmFloatSocket', 'Width', default_value = 0.1)
        self.add_input('ArmFloatSocket', 'Thickness')
        self.add_input('ArmFloatSocket', 'Start')
        self.add_input('ArmFloatSocket', 'End', default_value = 1.0)
        self.add_input('ArmBoolSocket', 'Fill Caps')

        self.add_output('ArmNodeSocketAction', 'Out')

    def draw_buttons(self, context, layout):
        layout.prop(self, 'property0')