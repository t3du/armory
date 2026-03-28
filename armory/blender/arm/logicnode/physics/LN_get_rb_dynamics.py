from arm.logicnode.arm_nodes import *

class SetRigidBodyDynamicsNode(ArmLogicTreeNode):
    bl_idname = 'LNSetRigidBodyDynamicsNode'
    bl_label = 'Set RB Dynamics'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Object')
        self.add_input('ArmBoolSocket', 'Is Static', default_value=False)
        self.add_input('ArmFloatSocket', 'Mass', default_value=1.0)
        self.add_output('ArmNodeSocketAction', 'Out')