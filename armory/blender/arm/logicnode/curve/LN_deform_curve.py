from arm.logicnode.arm_nodes import *

class DeformCurveNode(ArmLogicTreeNode):
    """Sets an object to deform using a curve."""
    bl_idname = 'LNDeformCurveNode'
    bl_label = 'Deform Curve'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Object')
        self.add_input('ArmNodeSocketObject', 'Curve')
        self.add_input('ArmIntSocket', 'Spline Index')
        self.add_input('ArmStringSocket', 'Forward Axis', default_value = 'X')
        self.add_input('ArmFloatSocket', 'Start')
        self.add_input('ArmFloatSocket', 'End', default_value = 1.0)

        self.add_output('ArmNodeSocketAction', 'Out')
