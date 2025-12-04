from arm.logicnode.arm_nodes import *

class GetPositionSpeakerNode(ArmLogicTreeNode):
    """Gets the current playback position of the given speaker object in seconds."""
    bl_idname = 'LNGetPositionSpeakerNode'
    bl_label = 'Get Position Speaker'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketObject', 'Speaker')
        self.add_output('ArmFloatSocket', 'Position (seconds)')
