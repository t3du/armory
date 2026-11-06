
from arm.logicnode.arm_nodes import *

class ChoiceNode(ArmLogicTreeNode):
    """Display a selection window to choose one choice.

    @input In: execution input.
    @input String: message to display.
    @input Choices: available options.

    @output True: a choice was selected.
    @output False: dialog was cancelled.
    @output String: selected choice.
    """
    bl_idname = 'LNChoiceNode'
    bl_label = 'Choice'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmStringSocket', 'String')
        self.add_input('ArmNodeSocketArray', 'Choices')

        self.add_output('ArmNodeSocketAction', 'True')
        self.add_output('ArmNodeSocketAction', 'False')
        self.add_output('ArmStringSocket', 'Choice')
        self.add_output('ArmIntSocket', 'Index')