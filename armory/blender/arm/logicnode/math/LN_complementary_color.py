from arm.logicnode.arm_nodes import *

class ComplementaryColorNode(ArmLogicTreeNode):
    """
    """

    bl_idname = 'LNComplementaryColorNode'
    bl_label = 'Complementary Color'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmColorSocket', 'Color In', default_value=[1.0, 1.0, 1.0, 1.0])

        self.add_output('ArmColorSocket', 'Comp. Color RGB Out')
        self.add_output('ArmColorSocket', 'Comp. Color RYB Out')
