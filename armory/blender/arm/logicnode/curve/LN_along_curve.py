from arm.logicnode.arm_nodes import *

class AlongCurveNode(ArmLogicTreeNode):
    """Sets an object along a curve."""
    bl_idname = 'LNAlongCurveNode'
    bl_label = 'Along Curve'
    arm_section = 'Curve'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Object')
        self.add_input('ArmNodeSocketObject', 'Curve')
        self.add_input('ArmIntSocket', 'Spline Index')
        self.add_input('ArmStringSocket', 'Forward Axis', default_value = 'X')
        self.add_input('ArmFloatSocket', 'Position')

        self.add_output('ArmNodeSocketAction', 'Out')