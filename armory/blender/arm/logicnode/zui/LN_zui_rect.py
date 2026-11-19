from arm.logicnode.arm_nodes import *


class ZuiRectNode(ArmLogicTreeNode):
    bl_idname = 'LNZuiRectNode'
    bl_label = 'Rect'
    arm_section = 'element'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'UI')
        self.add_input('ArmColorSocket', 'Color', default_value=[1.0, 1.0, 1.0, 1.0])
        self.add_input('ArmFloatSocket', 'Strength', default_value=1.0)
        self.add_input('ArmBoolSocket', 'Filled')
        self.add_input('ArmFloatSocket', 'X')
        self.add_input('ArmFloatSocket', 'Y')
        self.add_input('ArmFloatSocket', 'W', default_value=10.0)
        self.add_input('ArmFloatSocket', 'H', default_value=10.0)

        self.add_output('ArmNodeSocketAction', 'Next')