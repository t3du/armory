from arm.logicnode.arm_nodes import *


class ConnectionGetNode(ArmLogicTreeNode):
    """Gets public properties from a PeerJS data connection."""

    bl_idname = 'LNConnectionGetNode'
    bl_label = 'Connection Get'
    arm_section = 'peer'

    def arm_init(self, context):
        self.add_input('ArmStringSocket', 'Connection ID')

        self.add_output('ArmStringSocket', 'Peer ID')
        self.add_output('ArmStringSocket', 'Label')
        self.add_output('ArmDynamicSocket', 'Metadata')
        self.add_output('ArmBoolSocket', 'Open')
