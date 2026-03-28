from arm.logicnode.arm_nodes import *

class SetRigidBodyAnimatedNode(ArmLogicTreeNode):
    bl_idname = 'LNSetRigidBodyAnimatedNode'
    bl_label = 'Set RB Animated'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Object')
        self.add_input('ArmBoolSocket', 'Animated', default_value=False)
        self.add_output('ArmNodeSocketAction', 'Out')