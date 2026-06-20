from arm.logicnode.arm_nodes import *

class GetObjectInstancedNode(ArmLogicTreeNode):
    """Gets the object instanced from an array of LOC, ROT and SCL."""
    bl_idname = 'LNGetObjectInstancedNode'
    bl_label = 'Get Object Instanced'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketObject', 'Object')
        
        self.add_output('ArmBoolSocket', 'Instanced', default_value=True)
        self.add_output('ArmIntSocket', 'Type')
        self.add_output('ArmIntSocket', 'Count')
        self.add_output('ArmIntSocket', 'Stride')
        self.add_output('ArmNodeSocketArray', 'Array Instanced')