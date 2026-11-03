from arm.logicnode.arm_nodes import *


class PeerNetworkNode(ArmLogicTreeNode):
    """Returns the PeerJS peer, connection, and media call maps."""

    bl_idname = 'LNPeerNetworkNode'
    bl_label = 'Peer Network'
    arm_section = 'peer'

    def arm_init(self, context):
        self.add_output('ArmDynamicSocket', 'Peers')
        self.add_output('ArmDynamicSocket', 'Connections')
        self.add_output('ArmDynamicSocket', 'Peer Connections')
        self.add_output('ArmDynamicSocket', 'Peer Connection Info')
        self.add_output('ArmDynamicSocket', 'Calls')
        self.add_output('ArmDynamicSocket', 'Peer Calls')
        self.add_output('ArmDynamicSocket', 'Peer Call Info')
