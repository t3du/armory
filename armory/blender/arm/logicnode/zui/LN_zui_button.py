from arm.logicnode.arm_nodes import *


class ZuiButtonNode(ArmLogicTreeNode):
    """Adds a button to the current Zui window."""
    bl_idname = 'LNZuiButtonNode'
    bl_label = 'Button'
    arm_section = 'element'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'UI')
        self.add_input('ArmStringSocket', 'Text', default_value='Button')
        self.add_input('ArmIntSocket', 'Align', default_value=1)
        self.add_input('ArmStringSocket', 'Label')
        self.add_input('ArmFloatSocket', 'Radius')

        self.add_output('ArmNodeSocketAction', 'Clicked')
        self.add_output('ArmNodeSocketAction', 'Next')
