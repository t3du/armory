from arm.logicnode.arm_nodes import *


class PeerNetworkGetNode(ArmLogicTreeNode):
    """Gets connection, call IDs, and info maps for a specific peer."""

    bl_idname = 'LNPeerNetworkGetNode'
    bl_label = 'Peer Network Get'
    arm_section = 'peer'

    def arm_init(self, context):
        self.add_input('ArmStringSocket', 'Peer ID')
        self.add_input('ArmBoolSocket', 'Open')

        self.add_output('ArmNodeSocketArray', 'Peers')
        self.add_output('ArmNodeSocketArray', 'Connections')
        self.add_output('ArmNodeSocketArray', 'Calls')
        self.add_output('ArmDynamicSocket', 'Peer Connections Info')
        self.add_output('ArmDynamicSocket', 'Peer Calls Info')
