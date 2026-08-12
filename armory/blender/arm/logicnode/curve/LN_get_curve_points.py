from arm.logicnode.arm_nodes import *

class GetCurvePointsNode(ArmLogicTreeNode):
    """Gets curve spline control points."""
    bl_idname = 'LNGetCurvePointsNode'
    bl_label = 'Get Curve Points'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketObject', 'Curve')
        self.add_input('ArmIntSocket', 'Spline Index')

        self.add_output('ArmNodeSocketArray', 'Points')
        self.add_output('ArmBoolSocket', 'Closed')

