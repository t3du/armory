from arm.logicnode.arm_nodes import *

class GetAssetsNode(ArmLogicTreeNode):
    """"""
    bl_idname = 'LNGetAssetsNode'
    bl_label = 'Get Assets'
    arm_section = 'Assets'
    arm_version = 1

    def arm_init(self, context):
        self.add_output('ArmNodeSocketArray', 'Assets')
