from arm.logicnode.arm_nodes import *


class PeerDisconnectNode(ArmLogicTreeNode):
    """Disconnects a PeerJS peer from the signaling server."""

    bl_idname = 'LNPeerDisconnectNode'
    bl_label = 'Peer Disconnect'
    arm_section = 'peer'

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmStringSocket', 'Peer ID')

        self.add_output('ArmNodeSocketAction', 'Out')
