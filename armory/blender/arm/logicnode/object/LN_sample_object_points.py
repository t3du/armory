from arm.logicnode.arm_nodes import *


class SampleObjectPointsNode(ArmLogicTreeNode):
    """
    Samples points and surface normals across a mesh object using a low-discrepancy distribution.
    """
    bl_idname = 'LNSampleObjectPointsNode'
    bl_label = 'Sample Object Points'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketObject', 'Object')
        self.add_input('ArmIntSocket', 'Sample')

        self.add_output('ArmNodeSocketArray', 'Point/Normal')