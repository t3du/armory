from arm.logicnode.arm_nodes import *


class CallCloseNode(ArmLogicTreeNode):
    """Closes a PeerJS media call."""

    bl_idname = 'LNCallCloseNode'
    bl_label = 'Call Close'
    arm_section = 'call'

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmStringSocket', 'Call ID')

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmNodeSocketAction', 'On Error')
        self.add_output('ArmDynamicSocket', 'Error')
