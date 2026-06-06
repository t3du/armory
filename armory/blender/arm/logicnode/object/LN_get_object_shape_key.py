from arm.logicnode.arm_nodes import *

class SetObjectShapeKeyNode(ArmLogicTreeNode):
    """Gets shape key value of the object"""
    bl_idname = 'LNGetObjectShapeKeyNode'
    bl_label = 'Get Object Shape Key'
    arm_section = 'props'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketObject', 'Object')
        self.add_input('ArmStringSocket', 'Shape Key')

        self.add_output('ArmFloatSocket', 'Value')
