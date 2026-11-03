from arm.logicnode.arm_nodes import *


class PeerOpenNode(ArmLogicTreeNode):
    """Starts one PeerJS peer and outputs its ID; an empty ID requests an automatically generated one."""

    bl_idname = 'LNPeerOpenNode'
    bl_label = 'Peer Open'
    arm_section = 'peer'

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmStringSocket', 'Peer ID')
        self.add_input('ArmDynamicSocket', 'Options')

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmNodeSocketAction', 'On Error')
        self.add_output('ArmStringSocket', 'Peer ID')
        self.add_output('ArmDynamicSocket', 'Error')
