from arm.logicnode.arm_nodes import *

class GetWorldDataNode(ArmLogicTreeNode):
    """Gets the World data of the active scene."""
    bl_idname = 'LNGetWorldDataNode'
    bl_label = 'Get World Data'
    arm_version = 1

    def arm_init(self, context):
        self.add_output('ArmStringSocket', 'World')
        self.add_output('ArmFloatSocket', 'Strength')
        self.add_output('ArmColorSocket', 'Color')
