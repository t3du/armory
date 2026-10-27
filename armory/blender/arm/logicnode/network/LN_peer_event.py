from arm.logicnode.arm_nodes import *


class PeerEventNode(ArmLogicTreeNode):
    """Listens for events on a PeerJS connection."""

    bl_idname = 'LNPeerEventNode'
    bl_label = 'Peer Event'
    arm_section = 'peer'

    def update_sockets(self, context):
        while len(self.outputs) > 1:
            self.outputs.remove(self.outputs[-1])
        if self.property0 in ('connection', 'data'):
            self.add_output('ArmStringSocket', 'Connection ID')
            self.add_output('ArmStringSocket', 'Peer ID')
            self.add_output('ArmStringSocket', 'Label')
            self.add_output('ArmDynamicSocket', 'Metadata')
        if self.property0 == 'data':
            self.add_output('ArmDynamicSocket', 'Data')
        if self.property0 == 'error':
            self.add_output('ArmDynamicSocket', 'Error')

    property0: HaxeEnumProperty(
        'property0',
        items=[
            ('connection', 'connection', 'An incoming peer connection was received'),
            ('data', 'data', 'Data was received on any connection for this peer'),
            ('disconnected', 'disconnected', 'The peer disconnected from the signaling server'),
            ('close', 'close', 'The peer was destroyed'),
            ('error', 'error', 'The peer emitted an error'),
        ],
        name='',
        default='connection',
        update=update_sockets
    )

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmStringSocket', 'Peer ID')

        self.add_output('ArmNodeSocketAction', 'Out')
        self.update_sockets(context)

    def draw_buttons(self, context, layout):
        layout.prop(self, 'property0')
