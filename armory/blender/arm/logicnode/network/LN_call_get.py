from arm.logicnode.arm_nodes import *


class CallGetNode(ArmLogicTreeNode):
    """Gets properties from a PeerJS media call."""

    bl_idname = 'LNCallGetNode'
    bl_label = 'Call Get'
    arm_section = 'call'

    def arm_init(self, context):
        self.add_input('ArmStringSocket', 'Call ID')

        self.add_output('ArmStringSocket', 'Peer ID')
        self.add_output('ArmDynamicSocket', 'Metadata')
        self.add_output('ArmBoolSocket', 'Open')
        self.add_output('ArmDynamicSocket', 'Stream From')
        self.add_output('ArmDynamicSocket', 'Stream To')
