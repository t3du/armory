from arm.logicnode.arm_nodes import *

class ColorsMixNode(ArmLogicTreeNode):
    """
    @see https://github.com/rvanwijnen/spectral.js 2023 Ronald van Wijnen.
    """

    bl_idname = 'LNColorsMixNode'
    bl_label = 'Colors Mix'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketArray', 'Colors')
        self.add_input('ArmNodeSocketArray', 'Factors')
        
        self.add_output('ArmColorSocket', 'Color')
