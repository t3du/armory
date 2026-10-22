from arm.logicnode.arm_nodes import *

class OpenFileNode(ArmLogicTreeNode):
    """Open File"""
    bl_idname = 'LNOpenFileNode'
    bl_label = 'Open File'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmStringSocket', 'Extension')

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmStringSocket', 'Name')
        self.add_output('ArmDynamicSocket', 'File')