
from arm.logicnode.arm_nodes import *

class MultiChoiceNode(ArmLogicTreeNode):
    """Display a selection window to choose choices.
    """
    bl_idname = 'LNMultiChoiceNode'
    bl_label = 'Multi Choice'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmStringSocket', 'String')
        self.add_input('ArmNodeSocketArray', 'Choices')
        self.add_input('ArmNodeSocketArray', 'Default')

        self.add_output('ArmNodeSocketAction', 'True')
        self.add_output('ArmNodeSocketAction', 'False')
        self.add_output('ArmNodeSocketArray', 'Choices')
        self.add_output('ArmIntSocket', 'Length')