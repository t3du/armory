from arm.logicnode.arm_nodes import *


class ZuiCheckNode(ArmLogicTreeNode):
    """Adds a check to the current Zui window."""
    bl_idname = 'LNZuiCheckNode'
    bl_label = 'Check'
    arm_section = 'element'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'UI')
        self.add_input('ArmStringSocket', 'Text', default_value='Checkbox')
        self.add_input('ArmStringSocket', 'Label')
        self.add_input('ArmBoolSocket', 'Initial Value')

        self.add_output('ArmNodeSocketAction', 'Changed')
        self.add_output('ArmNodeSocketAction', 'Next')
        self.add_output('ArmBoolSocket', 'Selected')
