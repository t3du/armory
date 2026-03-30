from arm.logicnode.arm_nodes import *

class GetRigidBodyDataNode(ArmLogicTreeNode):
    """Returns the data of the given rigid body."""
    bl_idname = 'LNGetRigidBodyDataNode'
    bl_label = 'Get RB Data'
    arm_section = 'props'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketObject', 'Object')

        self.add_output('ArmBoolSocket', 'Is RB')
        self.add_output('ArmIntSocket', 'Collision Group')
        self.add_output('ArmIntSocket', 'Collision Mask')
        self.add_output('ArmBoolSocket', 'Is Animated')
        self.add_output('ArmBoolSocket', 'Is Static')
        self.add_output('ArmFloatSocket', 'Linear Damping')
        self.add_output('ArmFloatSocket', 'Angular Damping')
        self.add_output('ArmFloatSocket', 'Friction')
        self.add_output('ArmFloatSocket', 'Angular Friction')
        self.add_output('ArmFloatSocket', 'Mass')
        self.add_output('ArmBoolSocket', 'Is Trigger')
        self.add_output('ArmFloatSocket', 'Bounciness')
        self.add_output('ArmBoolSocket', 'Gravity Enabled')
        self.add_output('ArmVectorSocket', 'Linear Factor')
        self.add_output('ArmVectorSocket', 'Angular Factor')