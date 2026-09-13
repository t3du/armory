from arm.logicnode.arm_nodes import *


class WriteSoundNode(ArmLogicTreeNode):
    """
    @seeNode Read File
    """
    bl_idname = 'LNWriteSoundNode'
    bl_label = 'Write Sound'
    arm_section = 'file'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'Start')
        self.add_input('ArmNodeSocketAction', 'Stop')
        self.add_input('ArmStringSocket', 'Sound File')
        self.add_input('ArmFloatSocket', 'Volume', default_value = 1.0)

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmNodeSocketAction', 'Done')
