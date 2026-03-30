from arm.logicnode.arm_nodes import *

class SetRigidBodyBouncinessNode(ArmLogicTreeNode):
    bl_idname = 'LNSetRigidBodyBouncinessNode'
    bl_label = 'Set RB Bounciness'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Object')
        self.add_input('ArmFloatSocket', 'Bounciness', default_value=0)
        self.add_output('ArmNodeSocketAction', 'Out')