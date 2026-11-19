from arm.logicnode.arm_nodes import *


class ZuiTextNode(ArmLogicTreeNode):
    """Adds a text label to the current Zui window."""
    bl_idname = 'LNZuiTextNode'
    bl_label = 'Text'
    arm_section = 'element'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'UI')
        self.add_input('ArmStringSocket', 'Text', default_value='Text')
        self.add_input('ArmIntSocket', 'Align')
        self.add_input('ArmColorSocket', 'Color', default_value =[0.0, 0.0, 0.0, 0.0])

        self.add_output('ArmNodeSocketAction', 'Next')
