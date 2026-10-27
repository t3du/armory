from arm.logicnode.arm_nodes import *


class PeerSendNode(ArmLogicTreeNode):
    """Sends data to a connected peer."""

    bl_idname = 'LNPeerSendNode'
    bl_label = 'Peer Send'
    arm_section = 'peer'

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmStringSocket', 'Connection ID')
        self.add_input('ArmDynamicSocket', 'Data')

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmNodeSocketAction', 'On Error')
        self.add_output('ArmDynamicSocket', 'Error')
