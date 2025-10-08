from arm.logicnode.arm_nodes import *

class SetDimensionNode(ArmLogicTreeNode):
    """Sets the dimension of the given object."""
    bl_idname = 'LNSetDimensionNode'
    bl_label = 'Set Object Dimension'
    arm_section = 'dimension'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Object')
        self.add_input('ArmVectorSocket', 'Dimension', default_value=[1.0, 1.0, 1.0])

        self.add_output('ArmNodeSocketAction', 'Out')
