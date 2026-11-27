
from arm.logicnode.arm_nodes import *


class MathExpressionNode(ArmLogicTreeNode):
    """Mathematical operations on values."""

    bl_idname = 'LNMathExpressionNode'
    bl_label = 'Math Expression'
    arm_version = 1

    num_params: IntProperty(default=2, min=0, max=26)

    @staticmethod
    def get_variable_name(index):
        return chr(ord('a') + index)

    def arm_init(self, context):
        self.add_output('ArmFloatSocket', 'Result')

        self.add_input('ArmBoolSocket', 'Clamp', default_value=False)
        self.add_input('ArmStringSocket', 'Expression', default_value='a + b')

        for i in range(self.num_params):
            self.add_input(
                'ArmFloatSocket',
                self.get_variable_name(i),
                default_value=0.0
            )

    def add_sockets(self):
        if self.num_params >= 26:
            return

        self.add_input(
            'ArmFloatSocket',
            self.get_variable_name(self.num_params),
            default_value=0.0
        )
        self.num_params += 1

    def remove_sockets(self):
        if self.num_params <= 0:
            return

        self.inputs.remove(self.inputs.values()[-1])
        self.num_params -= 1

    def draw_buttons(self, context, layout):
        # Register node for operator callbacks
        self.register_id()

        row = layout.row(align=True)

        add = row.column()
        add.enabled = self.num_params < 26

        op = add.operator(
            'arm.node_call_func',
            text='Add Param',
            icon='PLUS'
        )
        op.node_index = self.get_id_str()
        op.callback_name = 'add_sockets'

        remove = row.column()
        remove.enabled = self.num_params > 0

        op = remove.operator(
            'arm.node_call_func',
            text='',
            icon='X'
        )
        op.node_index = self.get_id_str()
        op.callback_name = 'remove_sockets'