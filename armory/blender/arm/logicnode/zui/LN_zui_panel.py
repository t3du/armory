from arm.logicnode.arm_nodes import *


class ZuiPanelNode(ArmLogicTreeNode):
    """Adds a collapsible panel with a separate flow for its contents."""
    bl_idname = 'LNZuiPanelNode'
    bl_label = 'Panel'
    arm_section = 'layout'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'UI')
        self.add_input('ArmStringSocket', 'Title', default_value='Panel')
        self.add_input('ArmBoolSocket', 'Tree Style')
        self.add_input('ArmBoolSocket', 'Filled', default_value=True)
        self.add_input('ArmBoolSocket', 'Pack When Collapsed', default_value=True)
        self.add_input('ArmBoolSocket', 'Initially Selected')

        self.add_output('ArmNodeSocketAction', 'Content')
        self.add_output('ArmNodeSocketAction', 'Changed')
        self.add_output('ArmNodeSocketAction', 'Next')
        self.add_output('ArmBoolSocket', 'Selected')
