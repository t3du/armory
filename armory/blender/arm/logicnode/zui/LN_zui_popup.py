from arm.logicnode.arm_nodes import *


class ZuiPopupNode(ArmLogicTreeNode):
    """Opens a modal popup whose content is built by connected Zui nodes."""
    bl_idname = 'LNZuiPopupNode'
    bl_label = 'Popup'
    arm_section = 'layout'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'Open')
        self.add_input('ArmNodeSocketAction', 'Close')
        self.add_input('ArmIntSocket', 'X', default_value=-1)
        self.add_input('ArmIntSocket', 'Y', default_value=-1)
        self.add_input('ArmIntSocket', 'Width', default_value=400)
        self.add_input('ArmIntSocket', 'Height', default_value=240)

        self.add_output('ArmNodeSocketAction', 'Next')
