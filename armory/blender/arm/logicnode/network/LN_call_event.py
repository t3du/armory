from arm.logicnode.arm_nodes import *


class CallEventNode(ArmLogicTreeNode):
    """Listens for stream, close, or error events on a specific media call."""

    bl_idname = 'LNCallEventNode'
    bl_label = 'Call Event'
    arm_section = 'call'

    def update_sockets(self, context):
        while len(self.inputs) > 1:
            self.inputs.remove(self.inputs[-1])
        self.add_input('ArmStringSocket', 'Call ID')

        while len(self.outputs) > 1:
            self.outputs.remove(self.outputs[-1])

        self.outputs[0].name = 'Out'
        if self.property0 == 'stream':
            self.add_output('ArmDynamicSocket', 'Stream From')
            self.add_output('ArmDynamicSocket', 'Stream To')
        elif self.property0 == 'error':
            self.add_output('ArmDynamicSocket', 'Error')

    property0: HaxeEnumProperty(
        'property0',
        items=[
            ('stream', 'Stream', 'A media stream was received or created'),
            ('close', 'Close', 'The media call was closed'),
            ('error', 'Error', 'The media call emitted an error')
        ],
        name='Event',
        default='stream',
        update=update_sockets
    )

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_output('ArmNodeSocketAction', 'Out')
        self.update_sockets(context)

    def draw_buttons(self, context, layout):
        layout.prop(self, 'property0')
