from arm.logicnode.arm_nodes import *


class ZuiUnindentNode(ArmLogicTreeNode):
    """Restores the UI width after an indent."""
    bl_idname = 'LNZuiUnindentNode'
    bl_label = 'Unindent'
    arm_section = 'layout'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'UI')
        self.add_input('ArmBoolSocket', 'Both Sides', default_value=True)

        self.add_output('ArmNodeSocketAction', 'Next')
