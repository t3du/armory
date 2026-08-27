from arm.logicnode.arm_nodes import *

class SetPitchSoundNode(ArmLogicTreeNode):
    """sets pitch of the given speaker object.

    @seeNode Play Speaker
    @seeNode Stop Speaker
    """
    bl_idname = 'LNSetPitchSoundNode'
    bl_label = 'Set Pitch Speaker'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Speaker')
        self.add_input('ArmFloatSocket', 'Pitch')

        self.add_output('ArmNodeSocketAction', 'Out')
