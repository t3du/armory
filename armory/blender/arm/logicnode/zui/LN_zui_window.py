from arm.logicnode.arm_nodes import *


class ZuiWindowNode(ArmLogicTreeNode):
    """Opens a window in the active Zui context."""
    bl_idname = 'LNZuiWindowNode'
    bl_label = 'Window'
    arm_section = 'layout'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'Draw')
        self.add_input('ArmFloatSocket', 'X', default_value=20)
        self.add_input('ArmFloatSocket', 'Y', default_value=20)
        self.add_input('ArmIntSocket', 'Width', default_value=300)
        self.add_input('ArmIntSocket', 'Height', default_value=240)
        self.add_input('ArmBoolSocket', 'Draggable', default_value=True)
        self.add_input('ArmBoolSocket', 'Relative')

        self.add_output('ArmNodeSocketAction', 'Content')
        self.add_output('ArmNodeSocketAction', 'Next')

