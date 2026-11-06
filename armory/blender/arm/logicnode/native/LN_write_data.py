from arm.logicnode.arm_nodes import *


class WriteDataNode(ArmLogicTreeNode):
    """Writes binary data to a downloaded file."""

    bl_idname = 'LNWriteDataNode'
    bl_label = 'Write Data'
    arm_section = 'file'

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmStringSocket', 'File')
        self.add_input('ArmDynamicSocket', 'Data')

        self.add_output('ArmNodeSocketAction', 'Out')
