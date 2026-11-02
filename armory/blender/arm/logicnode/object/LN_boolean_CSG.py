from arm.logicnode.arm_nodes import *

class BooleanCSGNode(ArmLogicTreeNode):
    """Boolean operations: Union/Subtract/Intersect."""

    bl_idname = 'LNBooleanCSGNode'
    bl_label = 'Boolean CSG'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Object A')
        self.add_input('ArmNodeSocketObject', 'Object B')
        self.add_input('ArmIntSocket', '0/1/2 = Union/Subtract/Intersect')
        self.add_input('ArmBoolSocket', 'Remove Objects')

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmNodeSocketObject', 'Object')
