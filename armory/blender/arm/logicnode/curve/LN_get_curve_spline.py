from arm.logicnode.arm_nodes import *

class GetCurveSplineNode(ArmLogicTreeNode):
    """Gets curve spline."""
    bl_idname = 'LNGetCurveSplineNode'
    bl_label = 'Get Curve Spline'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketObject', 'Curve')
        self.add_input('ArmIntSocket', 'Spline Index')

        self.add_output('ArmNodeSocketArray', 'Points')
        self.add_output('ArmBoolSocket', 'Closed')
        self.add_output('ArmIntSocket', 'Resolution')

