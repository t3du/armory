from arm.logicnode.arm_nodes import *


class SeparateObjectNode(ArmLogicTreeNode):
    """Separates an object's mesh by material, vertex group, or loose part."""

    bl_idname = 'LNSeparateObjectNode'
    bl_label = 'Separate Object'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Object')
        self.add_input('ArmIntSocket', '0/1/2 = Loose Parts/Vertex Groups/Material')
        self.add_input('ArmBoolSocket', 'Remove Object')

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmNodeSocketAction', 'True')
        self.add_output('ArmNodeSocketAction', 'False')
        self.add_output('ArmNodeSocketArray', 'Objects')