from arm.logicnode.arm_nodes import *


class ConnectionCloseNode(ArmLogicTreeNode):
    """Closes a PeerJS data connection."""

    bl_idname = 'LNConnectionCloseNode'
    bl_label = 'Connection Close'
    arm_section = 'peer'

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmStringSocket', 'Connection ID')

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmNodeSocketAction', 'On Error')
        self.add_output('ArmDynamicSocket', 'Error')
