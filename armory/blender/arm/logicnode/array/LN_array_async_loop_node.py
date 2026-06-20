from arm.logicnode.arm_nodes import *


class ArrayAsyncLoopNode(ArmLogicTreeNode):
    """Loops through each item of the given array."""
    bl_idname = 'LNArrayAsyncLoopNode'
    bl_label = 'Array Async Loop'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketArray', 'Array')
        self.add_input('ArmIntSocket', 'Async Items')

        self.add_output('ArmNodeSocketAction', 'Loop')
        self.add_output('ArmDynamicSocket', 'Value')
        self.add_output('ArmIntSocket', 'Index')
        self.add_output('ArmNodeSocketAction', 'Done')
