from arm.logicnode.arm_nodes import *


class ZuiInlineRadioNode(ArmLogicTreeNode):
    """Draws an inline radio group from semicolon-separated options."""
    bl_idname = 'LNZuiInlineRadioNode'
    bl_label = 'Inline Radio'
    arm_section = 'element'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'UI')
        self.add_input('ArmNodeSocketArray', 'Texts')
        self.add_input('ArmIntSocket', 'Align')
        self.add_input('ArmIntSocket', 'Initial Position')

        self.add_output('ArmNodeSocketAction', 'Changed')
        self.add_output('ArmNodeSocketAction', 'Next')
        self.add_output('ArmIntSocket', 'Position')

