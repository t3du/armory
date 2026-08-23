from arm.logicnode.arm_nodes import *

class SetRigidBodyFrictionNode (ArmLogicTreeNode):
    """Sets the friction of the given rigid body."""
    bl_idname = 'LNSetRigidBodyFrictionNode'
    bl_label = 'Set RB Friction'
    bl_icon = 'NONE'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'RB')
        self.add_input('ArmFloatSocket', 'Friction', default_value=0.5)
        self.add_input('ArmFloatSocket', 'Angular Friction', default_value=0.1)

        self.add_output('ArmNodeSocketAction', 'Out')
