from arm.logicnode.arm_nodes import *


class PeerNetworkNode(ArmLogicTreeNode):
    """Returns the PeerJS peer and connection maps."""

    bl_idname = 'LNPeerNetworkNode'
    bl_label = 'Peer Network'
    arm_section = 'peer'

    def arm_init(self, context):
        self.add_output('ArmDynamicSocket', 'Peers')
        self.add_output('ArmDynamicSocket', 'Connections')
        self.add_output('ArmDynamicSocket', 'Peer Connections')
        self.add_output('ArmDynamicSocket', 'Peer Connection Info')
