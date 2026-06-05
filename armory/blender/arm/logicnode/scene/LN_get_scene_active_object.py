from arm.logicnode.arm_nodes import *

class ActiveSceneObjectNode(ArmLogicTreeNode):
    """Returns the active scene."""
    bl_idname = 'LNActiveSceneObjectNode'
    bl_label = 'Get Scene Active Object'
    arm_version = 1

    def arm_init(self, context):
        self.add_output('ArmNodeSocketObject', 'Scene')
