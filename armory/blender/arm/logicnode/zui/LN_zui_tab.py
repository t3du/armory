from arm.logicnode.arm_nodes import *


class ZuiTabNode(ArmLogicTreeNode):
    """Draws tabs and builds the active tab's content."""
    bl_idname = 'LNZuiTabNode'
    bl_label = 'Tab'
    arm_section = 'layout'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'UI')
        self.add_input('ArmNodeSocketArray', 'Tabs')
        self.add_input('ArmNodeSocketArray', 'Colors')
        self.add_input('ArmBoolSocket', 'Vertical')
        self.add_input('ArmIntSocket', 'Initial Position')

        self.add_output('ArmNodeSocketAction', 'Content')
        self.add_output('ArmNodeSocketAction', 'Changed')
        self.add_output('ArmNodeSocketAction', 'Next')
        self.add_output('ArmIntSocket', 'Position')
        
