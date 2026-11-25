from arm.logicnode.arm_nodes import *


class ZuiTooltipImageNode(ArmLogicTreeNode):
    """Sets a tooltip  image at the current UI cursor; use a state action to gate it."""
    bl_idname = 'LNZuiTooltipImageNode'
    bl_label = 'Tooltip Image'
    arm_section = 'element'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'UI')
        self.add_input('ArmStringSocket', 'Image')
        self.add_input('ArmIntSocket', 'Max Width')

        self.add_output('ArmNodeSocketAction', 'Next')
