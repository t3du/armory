from arm.logicnode.arm_nodes import *

class GetCurveDataNode(ArmLogicTreeNode):
    """Gets curve data."""
    bl_idname = 'LNGetCurveDataNode'
    bl_label = 'Get Curve Data'
    arm_section = 'Curve'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketObject', 'Curve')

        self.add_output('ArmIntSocket', 'Splines Length')
        self.add_output('ArmIntSocket', 'Equidistant Samples')
        self.add_output('ArmBoolSocket', 'Draw')
        self.add_output('ArmFloatSocket', 'Strength')
        self.add_output('ArmColorSocket', 'Color')
        self.add_output('ArmNodeSocketObject', 'Curve Mesh')
        
        

