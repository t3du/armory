from arm.logicnode.arm_nodes import *

class GetAreaLightDataNode(ArmLogicTreeNode):
    """Gets the data of the given area light."""
    bl_idname = 'LNGetAreaLightDataNode'
    bl_label = 'Get Area Light Data'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketObject', 'Light')

        self.add_output('ArmFloatSocket', 'Size X')
        self.add_output('ArmFloatSocket', 'Size Y')
