from arm.logicnode.arm_nodes import *

class GetSpeakerDataNode(ArmLogicTreeNode):
    """Gets the data of the given speaker."""
    bl_idname = 'LNGetSpeakerDataNode'
    bl_label = 'Get Speaker Data'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketObject', 'Speaker')

        self.add_output('ArmFloatSocket', 'Volume')
        self.add_output('ArmFloatSocket', 'Pitch')
        self.add_output('ArmIntSocket', 'Channels')
        self.add_output('ArmNodeSocketArray', 'Length')
        self.add_output('ArmNodeSocketArray', 'Position')
