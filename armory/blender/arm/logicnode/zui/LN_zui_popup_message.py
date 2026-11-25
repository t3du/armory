from arm.logicnode.arm_nodes import *


class ZuiPopupMessageNode(ArmLogicTreeNode):
    """Opens a modal popup message."""
    bl_idname = 'LNZuiPopupMessageNode'
    bl_label = 'Popup Message'
    arm_section = 'element'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'Open')
        self.add_input('ArmNodeSocketAction', 'Close')
        self.add_input('ArmStringSocket', 'Title')
        self.add_input('ArmStringSocket', 'Message')