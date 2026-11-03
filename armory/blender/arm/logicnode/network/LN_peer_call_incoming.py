from arm.logicnode.arm_nodes import *


class PeerCallIncomingNode(ArmLogicTreeNode):
    """Triggers when a PeerJS peer receives an incoming media call."""

    bl_idname = 'LNPeerCallIncomingNode'
    bl_label = 'Peer Call Incoming'
    arm_section = 'call'

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmStringSocket', 'Peer ID')

        self.add_output('ArmNodeSocketAction', 'On Call')
        self.add_output('ArmStringSocket', 'Call ID')
        self.add_output('ArmStringSocket', 'Peer ID')
        self.add_output('ArmDynamicSocket', 'Metadata')
