from arm.logicnode.arm_nodes import *

class SetMaterialsNode(ArmLogicTreeNode):
    """TO DO."""
    bl_idname = 'LNSetMaterialsNode'
    bl_label = 'Set Object Materials'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Object')
        self.add_input('ArmNodeSocketArray', 'Materials')

        self.add_output('ArmNodeSocketAction', 'Out')
