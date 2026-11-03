from arm.logicnode.arm_nodes import *

class CopyToClipboardNode(ArmLogicTreeNode):
    """Copies the given text to the system clipboard"""
    bl_idname = 'LNCopyToClipboardNode'
    bl_label = 'Copy To Clipboard'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmStringSocket', 'Text')

        self.add_output('ArmNodeSocketAction', 'Out')