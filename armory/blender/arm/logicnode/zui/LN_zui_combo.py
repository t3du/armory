from arm.logicnode.arm_nodes import *


class ZuiComboNode(ArmLogicTreeNode):
    """Adds a combo populated from an array of strings."""
    bl_idname = 'LNZuiComboNode'
    bl_label = 'Combo'
    arm_section = 'element'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'UI')
        self.add_input('ArmNodeSocketArray', 'Texts')
        self.add_input('ArmStringSocket', 'Label')
        self.add_input('ArmBoolSocket', 'Show Label')
        self.add_input('ArmIntSocket', 'Align')
        self.add_input('ArmBoolSocket', 'Search Bar')
        self.add_input('ArmIntSocket', 'Initial Position')

        self.add_output('ArmNodeSocketAction', 'Changed')
        self.add_output('ArmNodeSocketAction', 'Next')
        self.add_output('ArmIntSocket', 'Position')
