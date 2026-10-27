from arm.logicnode.arm_nodes import *

class SetTextDataNode(ArmLogicTreeNode):
    """Sets text data."""
    bl_idname = 'LNSetTextDataNode'
    bl_label = 'Set Text Data'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Text')
        self.add_input('ArmStringSocket', 'Font File')
        self.add_input('ArmStringSocket', 'String')
        self.add_input('ArmFloatSocket', 'World Scale', default_value=0.001)
        self.add_input('ArmFloatSocket', 'Extrusion Depth')
        self.add_input('ArmIntSocket', 'Curve Steps', default_value=8)
        self.add_input('ArmDynamicSocket', 'Fill Material')
        self.add_input('ArmDynamicSocket', 'Side Material')
        self.add_input('ArmColorSocket', 'Outline Color')
        self.add_input('ArmFloatSocket', 'Outline Strength')
        self.add_input('ArmBoolSocket', 'Fill')

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmNodeSocketObject', 'Text Mesh')