from arm.logicnode.arm_nodes import *

class DelayNode(ArmLogicTreeNode):
    """Delay"""
    bl_idname = 'LNDelayNode'
    bl_label = 'Delay'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('NodeSocketFloat', 'Time')

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('NodeSocketFloat', 'Time')