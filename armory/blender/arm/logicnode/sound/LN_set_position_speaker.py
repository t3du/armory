from arm.logicnode.arm_nodes import *

class SetPositionSpeakerNode(ArmLogicTreeNode):
    """Sets the playback position of the given speaker object.
    This node allows you to "scrub" through audio by setting the current playback position
    to a specific time in seconds. The speaker must be playing for this to take effect.
    """
    bl_idname = 'LNSetPositionSpeakerNode'
    bl_label = 'Set Position Speaker'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Speaker')
        self.add_input('ArmFloatSocket', 'Position')

        self.add_output('ArmNodeSocketAction', 'Out')
