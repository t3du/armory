from arm.logicnode.arm_nodes import *


class PeerDestroyNode(ArmLogicTreeNode):
    """Destroys a PeerJS peer and closes its connections."""

    bl_idname = 'LNPeerDestroyNode'
    bl_label = 'Peer Destroy'
    arm_section = 'peer'

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmStringSocket', 'Peer ID')

        self.add_output('ArmNodeSocketAction', 'Out')
