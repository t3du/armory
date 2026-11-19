from arm.logicnode.arm_nodes import *


class ZuiSeparatorNode(ArmLogicTreeNode):
    """Adds spacing or a dividing line between UI elements."""
    bl_idname = 'LNZuiSeparatorNode'
    bl_label = 'Separator'
    arm_section = 'layout'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'UI')
        self.add_input('ArmIntSocket', 'Height', default_value=4)
        self.add_input('ArmBoolSocket', 'Fill', default_value=True)

        self.add_output('ArmNodeSocketAction', 'Next')
