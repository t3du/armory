from arm.logicnode.arm_nodes import *

class SetRigidBodyGravityNode(ArmLogicTreeNode):
    """Sets the gravity for the given rigid body."""
    bl_idname = 'LNSetRigidBodyGravityNode'
    bl_label = 'Set RB Gravity'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'RB')
        self.add_input('ArmVectorSocket', 'Gravity')

        self.add_output('ArmNodeSocketAction', 'Out')
