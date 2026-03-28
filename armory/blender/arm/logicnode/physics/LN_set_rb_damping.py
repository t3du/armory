from arm.logicnode.arm_nodes import *

class SetRigidBodyDampingNode(ArmLogicTreeNode):
    """Sets the linear and angular damping of a rigid body."""
    bl_idname = 'LNSetRigidBodyDampingNode'
    bl_label = 'Set RB Damping'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Object')
        self.add_input('ArmFloatSocket', 'Linear Damping', default_value=0.04)
        self.add_input('ArmFloatSocket', 'Angular Damping', default_value=0.1)
        self.add_output('ArmNodeSocketAction', 'Out')