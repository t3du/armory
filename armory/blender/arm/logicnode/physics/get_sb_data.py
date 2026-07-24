from arm.logicnode.arm_nodes import *

class GetSoftBodyDataNode(ArmLogicTreeNode):
    bl_idname = 'LNGetSoftBodyDataNode'
    bl_label = 'Get SB Data'
    arm_section = 'softbody'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketObject', 'Object')
        
        self.add_output('ArmBoolSocket', 'Has SB')
        self.add_output('ArmFloatSocket', 'Mass')
        self.add_output('ArmFloatSocket', 'Bend')
        self.add_output('ArmIntSocket', 'Shape')
        self.add_output('ArmFloatSocket', 'Margin')
        self.add_output('ArmVectorSocket', 'World Center')
        self.add_output('ArmFloatSocket', 'Friction')
        self.add_output('ArmFloatSocket', 'Damping')
        self.add_output('ArmFloatSocket', 'Pressure')
        self.add_output('ArmFloatSocket', 'Linear Stiffness')
        self.add_output('ArmFloatSocket', 'Angular Stiffness')