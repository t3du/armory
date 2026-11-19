from arm.logicnode.arm_nodes import *


class ZuiRadioNode(ArmLogicTreeNode):
    """Draws one radio option for each string in the input array.

    The Position output is the index selected in the array, starting at zero.
    """
    bl_idname = 'LNZuiRadioNode'
    bl_label = 'Radio'
    arm_section = 'element'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'UI')
        self.add_input('ArmNodeSocketArray', 'Texts')
        self.add_input('ArmNodeSocketArray', 'Labels')
        self.add_input('ArmIntSocket', 'Initial Position')

        self.add_output('ArmNodeSocketAction', 'Changed')
        self.add_output('ArmNodeSocketAction', 'Next')
        self.add_output('ArmIntSocket', 'Position')
