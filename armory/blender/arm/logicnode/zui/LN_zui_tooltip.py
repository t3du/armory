from arm.logicnode.arm_nodes import *


class ZuiTooltipNode(ArmLogicTreeNode):
    """Sets a tooltip at the current UI cursor; use a state action to gate it."""
    bl_idname = 'LNZuiTooltipNode'
    bl_label = 'Tooltip'
    arm_section = 'element'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'UI')
        self.add_input('ArmStringSocket', 'Text')

        self.add_output('ArmNodeSocketAction', 'Next')
