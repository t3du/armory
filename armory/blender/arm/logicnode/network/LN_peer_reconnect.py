from arm.logicnode.arm_nodes import *


class PeerReconnectNode(ArmLogicTreeNode):
    """Reconnects a disconnected PeerJS peer to the signaling server."""

    bl_idname = 'LNPeerReconnectNode'
    bl_label = 'Peer Reconnect'
    arm_section = 'peer'

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmStringSocket', 'Peer ID')

        self.add_output('ArmNodeSocketAction', 'Out')
