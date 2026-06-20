from arm.logicnode.arm_nodes import *

class GetSpotLightDataNode(ArmLogicTreeNode):
    """Gets the data of the given spot light."""
    bl_idname = 'LNGetSpotLightDataNode'
    bl_label = 'Get Spot Light Data'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketObject', 'Light')

        self.add_output('ArmFloatSocket', 'Size')
        self.add_output('ArmFloatSocket', 'Blend')
