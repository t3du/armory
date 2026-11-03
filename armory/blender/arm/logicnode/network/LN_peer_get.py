from arm.logicnode.arm_nodes import *


class PeerGetNode(ArmLogicTreeNode):
    """Gets state properties from an opened PeerJS peer."""

    bl_idname = 'LNPeerGetNode'
    bl_label = 'Peer Get'
    arm_section = 'peer'

    def arm_init(self, context):
        self.add_input('ArmStringSocket', 'Peer ID')

        self.add_output('ArmBoolSocket', 'Open')
        self.add_output('ArmBoolSocket', 'Disconnected')
        self.add_output('ArmBoolSocket', 'Destroyed')
