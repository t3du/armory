from arm.logicnode.arm_nodes import *


class ZuiColorFieldNode(ArmLogicTreeNode):
    """Adds a compact color swatch that opens the color wheel popup."""
    bl_idname = 'LNZuiColorFieldNode'
    bl_label = 'Color Field'
    arm_section = 'element'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'UI')
        self.add_input('ArmColorSocket', 'Initial Color', default_value=[1.0, 1.0, 1.0, 1.0])
        self.add_input('ArmBoolSocket', 'Alpha', default_value=False)

        self.add_output('ArmNodeSocketAction', 'Changed')
        self.add_output('ArmNodeSocketAction', 'Next')
        self.add_output('ArmColorSocket', 'Color')
