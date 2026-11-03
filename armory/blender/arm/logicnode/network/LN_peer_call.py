from arm.logicnode.arm_nodes import *


class PeerCallNode(ArmLogicTreeNode):
    """Captures the selected local media and starts an outgoing PeerJS call."""

    bl_idname = 'LNPeerCallNode'
    bl_label = 'Peer Call'
    arm_section = 'call'

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmStringSocket', 'Peer ID From')
        self.add_input('ArmStringSocket', 'Peer ID To')
        self.add_input('ArmIntSocket', 'Video (0=None, 1=Camera, 2=Screen)', default_value=1)
        self.add_input('ArmBoolSocket', 'Audio', default_value=True)
        self.add_input('ArmDynamicSocket', 'Metadata')

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmNodeSocketAction', 'On Error')
        self.add_output('ArmStringSocket', 'Call ID')
        self.add_output('ArmDynamicSocket', 'Error')
