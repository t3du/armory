from arm.logicnode.arm_nodes import *


class IfNullNode(ArmLogicTreeNode):
    """"""
    bl_idname = 'LNIfNullNode'
    bl_label = 'If Null'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmDynamicSocket', 'Value')

        self.add_output('ArmNodeSocketAction', 'True')
        self.add_output('ArmNodeSocketAction', 'False')
