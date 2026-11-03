from arm.logicnode.arm_nodes import *


class PeerConnectNode(ArmLogicTreeNode):
    """Connects one local peer ID to a remote peer ID."""

    bl_idname = 'LNPeerConnectNode'
    bl_label = 'Peer Connect'
    arm_section = 'peer'

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmStringSocket', 'Peer ID From')
        self.add_input('ArmStringSocket', 'Peer ID To')
        self.add_input('ArmStringSocket', 'Label')
        self.add_input('ArmStringSocket', 'Connection ID')
        self.add_input('ArmDynamicSocket', 'Metadata')

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmNodeSocketAction', 'On Error')
        self.add_output('ArmStringSocket', 'Connection ID')
        self.add_output('ArmDynamicSocket', 'Error')
