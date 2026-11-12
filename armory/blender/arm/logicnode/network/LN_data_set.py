from arm.logicnode.arm_nodes import *


class DataSetNode(ArmLogicTreeNode):
    """Creates a Dynamic data object from Key/Value pairs."""

    bl_idname = 'LNDataSetNode'
    bl_label = 'Data Set'
    arm_section = 'data'
    arm_version = 1
    min_entries = 1

    num_entries: IntProperty(default=1, min=1)

    def __init__(self):
        super().__init__()
        array_nodes[str(id(self))] = self

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmStringSocket', 'Key 0')
        self.add_input('ArmDynamicSocket', 'Value 0')

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmDynamicSocket', 'Data')

    def draw_buttons(self, context, layout):
        row = layout.row(align=True)

        op = row.operator('arm.node_call_func', text='New', icon='PLUS')
        op.node_index = str(id(self))
        op.callback_name = 'add_entry'

        column = row.column(align=True)
        op = column.operator('arm.node_call_func', text='', icon='X')
        op.node_index = str(id(self))
        op.callback_name = 'remove_entry'
        column.enabled = self.num_entries > self.min_entries

    def add_entry(self):
        self.add_input('ArmStringSocket', f'Key {self.num_entries}')
        self.add_input('ArmDynamicSocket', f'Value {self.num_entries}')
        self.num_entries += 1

    def remove_entry(self):
        if self.num_entries <= self.min_entries:
            return

        self.inputs.remove(self.inputs[-1])
        self.inputs.remove(self.inputs[-1])
        self.num_entries -= 1

    def draw_label(self):
        return f'{self.bl_label}: [{self.num_entries}]'
