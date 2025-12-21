from arm.logicnode.arm_nodes import *

class GetCrowdDataNode(ArmLogicTreeNode):
    """Gets the speed and position of the crowd"""
    bl_idname = 'LNGetCrowdDataNode'
    bl_label = 'Get Crowd Data'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketObject', 'Object')

        self.add_output('ArmVectorSocket', 'Speed')
        self.add_output('ArmVectorSocket', 'Location')
        self.add_output('ArmVectorSocket', 'Target Location')
        self.add_output('ArmIntSocket', 'Id')
        self.add_output('ArmNodeSocketArray', 'Path')
