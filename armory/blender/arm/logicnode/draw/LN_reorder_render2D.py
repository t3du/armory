from arm.logicnode.arm_nodes import *


class ReorderRender2DNode(ArmLogicTreeNode):

    bl_idname = 'LNReorderRender2DNode'
    bl_label = 'Reorder Render2D'
    arm_section = 'draw'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmDynamicSocket', 'Render2D')
        self.add_input('ArmIntSocket', 'Index')

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmIntSocket', 'Index')
