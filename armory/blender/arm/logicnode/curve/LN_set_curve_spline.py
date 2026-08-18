from arm.logicnode.arm_nodes import *

class SetCurveSplineNode(ArmLogicTreeNode):
    """Sets curve spline."""
    bl_idname = 'LNSetCurveSplineNode'
    bl_label = 'Set Curve Spline'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Curve')
        self.add_input('ArmIntSocket', 'Spline Index')
        #self.add_output('ArmNodeSocketArray', 'Points')
        self.add_input('ArmBoolSocket', 'Closed')
        self.add_input('ArmIntSocket', 'Resolution', default_value = 12)

        self.add_output('ArmNodeSocketAction', 'Out')

