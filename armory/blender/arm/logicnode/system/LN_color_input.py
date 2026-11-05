from arm.logicnode.arm_nodes import *

class ColorInputNode(ArmLogicTreeNode):
    """
    color prompt
    """
    bl_idname = 'LNColorInputNode'
    bl_label = 'Color Input'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmStringSocket', 'String')
        self.add_input('ArmColorSocket', 'Default')

        self.add_output('ArmNodeSocketAction', 'True')
        self.add_output('ArmNodeSocketAction', 'False')
        self.add_output('ArmColorSocket', 'Color')
