from arm.logicnode.arm_nodes import *


class ZuiMenuNode(ArmLogicTreeNode):
    """Draws a horizontal menu from an array of strings."""
    bl_idname = 'LNZuiMenuNode'
    bl_label = 'Menu'
    arm_section = 'layout'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'UI')
        self.add_input('ArmNodeSocketArray', 'Items')

        self.add_output('ArmNodeSocketAction', 'Changed')
        self.add_output('ArmNodeSocketAction', 'Next')
        self.add_output('ArmIntSocket', 'Position')
