from arm.logicnode.arm_nodes import *


class DataGetNode(ArmLogicTreeNode):
    """Gets values from a Dynamic data object by key."""

    bl_idname = 'LNDataGetNode'
    bl_label = 'Data Get'
    arm_section = 'data'
    arm_version = 1
    min_keys = 1

    num_keys: IntProperty(default=1, min=1)

    def __init__(self):
        super().__init__()
        array_nodes[str(id(self))] = self

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmDynamicSocket', 'Data')

        self.add_output('ArmNodeSocketAction', 'Out')

        self.add_input('ArmStringSocket', 'Key 0')

        self.add_output('ArmNodeSocketAction', 'Output 0')
        self.add_output('ArmDynamicSocket', 'Value 0')

    def draw_buttons(self, context, layout):
        row = layout.row(align=True)

        op = row.operator('arm.node_call_func', text='New', icon='PLUS')
        op.node_index = str(id(self))
        op.callback_name = 'add_key'

        column = row.column(align=True)
        op = column.operator('arm.node_call_func', text='', icon='X')
        op.node_index = str(id(self))
        op.callback_name = 'remove_key'
        column.enabled = self.num_keys > self.min_keys

    def add_key(self):
        self.add_input('ArmStringSocket', f'Key {self.num_keys}')

        self.add_output('ArmNodeSocketAction', f'Output {self.num_keys}')
        self.add_output('ArmDynamicSocket', f'Value {self.num_keys}')

        self.num_keys += 1

    def remove_key(self):
        if self.num_keys <= self.min_keys:
            return

        self.outputs.remove(self.outputs[-1])
        self.outputs.remove(self.outputs[-1])
        self.inputs.remove(self.inputs[-1])

        self.num_keys -= 1

    def draw_label(self):
        return f'{self.bl_label}: [{self.num_keys}]'
