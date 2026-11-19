from arm.logicnode.arm_nodes import *


class ZuiColorWheelNode(ArmLogicTreeNode):
    """Adds the full Zui color wheel editor."""
    bl_idname = 'LNZuiColorWheelNode'
    bl_label = 'Color Wheel'
    arm_section = 'element'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'UI')
        self.add_input('ArmColorSocket', 'Initial Color', default_value=[1.0, 1.0, 1.0, 1.0])
        self.add_input('ArmBoolSocket', 'Alpha')
        self.add_input('ArmBoolSocket', 'Color Preview')

        self.add_output('ArmNodeSocketAction', 'Changed')
        self.add_output('ArmNodeSocketAction', 'Next')
        self.add_output('ArmColorSocket', 'Color')
