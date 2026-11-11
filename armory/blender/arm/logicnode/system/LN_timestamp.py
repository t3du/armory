from arm.logicnode.arm_nodes import *

class TimestampNode(ArmLogicTreeNode):
    """Timestamp"""
    bl_idname = 'LNTimestampNode'
    bl_label = 'Time'
    arm_version = 1

    def arm_init(self, context):
        self.add_output('NodeSocketFloat', 'Time')