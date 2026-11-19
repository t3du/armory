from arm.logicnode.arm_nodes import *


class ZuiRowNode(ArmLogicTreeNode):
    """Sets column widths for the next UI elements in the current row."""
    bl_idname = 'LNZuiRowNode'
    bl_label = 'Row'
    arm_section = 'layout'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'UI')
        self.add_input('ArmNodeSocketArray', 'Ratios')

        self.add_output('ArmNodeSocketAction', 'Next')
