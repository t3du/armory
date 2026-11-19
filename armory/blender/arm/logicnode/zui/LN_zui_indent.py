from arm.logicnode.arm_nodes import *


class ZuiIndentNode(ArmLogicTreeNode):
    """Indents the following UI elements."""
    bl_idname = 'LNZuiIndentNode'
    bl_label = 'Indent'
    arm_section = 'layout'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'UI')
        self.add_input('ArmBoolSocket', 'Both Sides', default_value=True)

        self.add_output('ArmNodeSocketAction', 'Next')
