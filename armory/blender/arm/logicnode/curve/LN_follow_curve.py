from arm.logicnode.arm_nodes import *

class FollowCurveNode(ArmLogicTreeNode):
    """Sets an object to follow a curve."""
    bl_idname = 'LNFollowCurveNode'
    bl_label = 'Follow Curve'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Object')
        self.add_input('ArmNodeSocketObject', 'Curve')
        self.add_input('ArmIntSocket', 'Spline Index')
        self.add_input('ArmStringSocket', 'Forward Axis', default_value = 'X')
        self.add_input('ArmFloatSocket', 'Speed')
        self.add_input('ArmBoolSocket', 'Forward', default_value = True)
        self.add_input('ArmBoolSocket', 'Cyclic')
        self.add_input('ArmFloatSocket', 'Start')

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmNodeSocketAction', 'Cycle')
        self.add_output('ArmFloatSocket', 'Progress')
