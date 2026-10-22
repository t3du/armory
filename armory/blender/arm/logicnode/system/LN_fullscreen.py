from arm.logicnode.arm_nodes import *

class FullscreenNode(ArmLogicTreeNode):
    """Copies the given text to the system clipboard"""
    bl_idname = 'LNFullscreenNode'
    bl_label = 'Fullscreen'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmBoolSocket', 'Fullscreen')

        self.add_output('ArmNodeSocketAction', 'Out')