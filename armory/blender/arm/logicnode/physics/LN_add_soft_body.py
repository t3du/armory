from arm.logicnode.arm_nodes import *

class AddSoftBodyNode(ArmLogicTreeNode):
    bl_idname = 'LNAddSoftBodyNode'
    bl_label = 'Add Soft Body'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Object')
        self.add_input('ArmIntSocket', 'Shape', default_value=0)
        self.add_input('ArmFloatSocket', 'Bend', default_value=0.5)
        self.add_input('ArmFloatSocket', 'Mass', default_value=1.0)
        self.add_input('ArmFloatSocket', 'Margin', default_value=0.04)
        self.add_input('ArmFloatSocket', 'Friction', default_value=0.5)
        self.add_input('ArmFloatSocket', 'Damping', default_value=0.01)
        self.add_input('ArmFloatSocket', 'Linear Stiffness', default_value=0.9)
        self.add_input('ArmFloatSocket', 'Angular Stiffness', default_value=0.9)
        self.add_input('ArmFloatSocket', 'Pressure', default_value=0.0)
        
        self.add_output('ArmNodeSocketAction', 'Out')