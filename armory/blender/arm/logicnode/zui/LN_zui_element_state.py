from arm.logicnode.arm_nodes import *


class ZuiElementStateNode(ArmLogicTreeNode):
    """Runs each matching interaction action before continuing to Next."""
    bl_idname = 'LNZuiElementStateNode'
    bl_label = 'Element State'
    arm_section = 'default'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'UI')

        self.add_output('ArmNodeSocketAction', 'Is Hovered')
        self.add_output('ArmNodeSocketAction', 'Is Started')
        self.add_output('ArmNodeSocketAction', 'Is Pushed')
        self.add_output('ArmNodeSocketAction', 'Is Released')
        self.add_output('ArmNodeSocketAction', 'Next')
