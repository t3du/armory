from arm.logicnode.arm_nodes import *

class TextSplitNode(ArmLogicTreeNode):
    """Sets text data."""
    bl_idname = 'LNTextSplitNode'
    bl_label = 'Text Split'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Text')
        self.add_input('ArmBoolSocket', 'Remove Text Mesh')
        self.add_input('ArmBoolSocket', 'Parent to Text')

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmNodeSocketArray', 'Text Meshes')