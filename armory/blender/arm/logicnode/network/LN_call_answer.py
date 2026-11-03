from arm.logicnode.arm_nodes import *


class CallAnswerNode(ArmLogicTreeNode):
    """Captures optional local media and answers an incoming PeerJS call."""

    bl_idname = 'LNCallAnswerNode'
    bl_label = 'Call Answer'
    arm_section = 'call'

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmStringSocket', 'Call ID')
        self.add_input('ArmIntSocket', 'Video (0=None, 1=Camera, 2=Screen)', default_value=1)
        self.add_input('ArmBoolSocket', 'Audio', default_value=True)

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmNodeSocketAction', 'On Error')
        self.add_output('ArmDynamicSocket', 'Error')
