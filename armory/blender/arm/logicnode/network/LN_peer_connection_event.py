from arm.logicnode.arm_nodes import *


class PeerConnectionEventNode(ArmLogicTreeNode):
    """Listens for an event on one PeerJS data connection."""

    bl_idname = 'LNPeerConnectionEventNode'
    bl_label = 'Connection Event'
    arm_section = 'peer'

    def update_sockets(self, context):
        while len(self.outputs) > 1:
            self.outputs.remove(self.outputs[-1])
        if self.property0 == 'data':
            self.add_output('ArmDynamicSocket', 'Data')
        elif self.property0 == 'error':
            self.add_output('ArmDynamicSocket', 'Error')

    property0: HaxeEnumProperty(
        'property0',
        items=[
            ('open', 'open', 'The connection opened'),
            ('data', 'data', 'Data was received on this connection'),
            ('close', 'close', 'The connection closed'),
            ('error', 'error', 'The connection emitted an error'),
        ],
        name='',
        default='open',
        update=update_sockets
    )

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmStringSocket', 'Connection ID')

        self.add_output('ArmNodeSocketAction', 'Out')
        self.update_sockets(context)

    def draw_buttons(self, context, layout):
        layout.prop(self, 'property0')
