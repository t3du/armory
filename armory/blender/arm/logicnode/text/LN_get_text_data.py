from arm.logicnode.arm_nodes import *

class GetTextDataNode(ArmLogicTreeNode):
    """Gets text data."""
    bl_idname = 'LNGetTextDataNode'
    bl_label = 'Get Text Data'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketObject', 'Text')

        self.add_output('ArmStringSocket', 'Font File')
        self.add_output('ArmStringSocket', 'String')
        self.add_output('ArmFloatSocket', 'World Scale')
        self.add_output('ArmFloatSocket', 'Extrusion Depth')
        self.add_output('ArmIntSocket', 'Curve Steps')
        self.add_output('ArmDynamicSocket', 'Fill Material')
        self.add_output('ArmDynamicSocket', 'Side Material')
        self.add_output('ArmColorSocket', 'Outline Color')
        self.add_output('ArmFloatSocket', 'Outline Strength')
        self.add_output('ArmNodeSocketObject', 'Text Mesh')
        self.add_output('ArmBoolSocket', 'Fill')