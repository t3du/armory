from arm.logicnode.arm_nodes import *

class GetLightDataNode(ArmLogicTreeNode):
    """Get lights data info."""
    bl_idname = 'LNGetLightDataNode'
    bl_label = 'Get Light Data'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketObject', 'Light')

        self.add_output('ArmIntSocket', 'Type')
        self.add_output('ArmFloatSocket', 'Strength')
        self.add_output('ArmColorSocket', 'Color')
        self.add_output('ArmBoolSocket', 'Shadow')
