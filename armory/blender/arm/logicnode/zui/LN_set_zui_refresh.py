from arm.logicnode.arm_nodes import *


class SetZuiThemeValuesNode(ArmLogicTreeNode):
    """
    """
    bl_idname = 'LNZuiRefreshNode'
    bl_label = 'Refresh'
    arm_section = 'default'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmDynamicSocket', 'UI')

        self.add_output('ArmNodeSocketAction', 'Out')