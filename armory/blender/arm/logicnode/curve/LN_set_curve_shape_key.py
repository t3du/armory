from arm.logicnode.arm_nodes import *

class SetCurveShapeKeyNode(ArmLogicTreeNode):
    """Sets shape key value of the curve"""
    bl_idname = 'LNSetCurveShapeKeyNode'
    bl_label = 'Set Curve Shape Key'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Curve')
        self.add_input('ArmStringSocket', 'Shape Key')
        self.add_input('ArmFloatSocket', 'Value')

        self.add_output('ArmNodeSocketAction', 'Out')
