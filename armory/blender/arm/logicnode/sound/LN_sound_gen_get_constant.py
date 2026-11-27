from arm.logicnode.arm_nodes import *


class SoundGenGetConstantNode(ArmLogicTreeNode):
    """
    @seeNode SoundGenDraw
    """
    bl_idname = 'LNSoundGenGetConstantNode'
    bl_label = 'SoundGen Get Constant'
    arm_section = 'gen-get'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmStringSocket', 'Constant')

        self.add_output('ArmFloatSocket', 'Frequency')
