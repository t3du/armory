from arm.logicnode.arm_nodes import *

class SetRigidBodyFactorNode(ArmLogicTreeNode):
    bl_idname = 'LNSetRigidBodyFactorNode'
    bl_label = 'Set RB Factor'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Object')
        self.add_input('ArmVectorSocket', 'Linear Factor', default_value=[1.0, 1.0, 1.0])
        self.add_input('ArmVectorSocket', 'Angular Factor', default_value=[1.0, 1.0, 1.0])
        self.add_output('ArmNodeSocketAction', 'Out')