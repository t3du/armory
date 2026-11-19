from arm.logicnode.arm_nodes import *


class ZuiContextNode(ArmLogicTreeNode):
    """Creates one Zui context for the connected UI and its windows."""
    bl_idname = 'LNZuiContextNode'
    bl_label = 'UI Context'
    arm_section = 'layout'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'Draw')
        self.add_input('ArmStringSocket', 'Font', default_value='font_default.ttf')
        self.add_input('ArmFloatSocket', 'Scale Factor', default_value=1.0)
        self.add_input('ArmIntSocket', 'Font Size')
        self.add_input('ArmStringSocket', 'Theme')

        self.add_output('ArmNodeSocketAction', 'UI')
        self.add_output('ArmDynamicSocket', 'UI')
