from arm.logicnode.arm_nodes import *

class SetCameraProjectionNode(ArmLogicTreeNode):
    """Sets the projection of the given camera."""
    bl_idname = 'LNSetCameraProjectionNode'
    bl_label = 'Set Camera Projection'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Camera')
        self.add_input('ArmIntSocket', 'Width')
        self.add_input('ArmIntSocket', 'Height')

        self.add_output('ArmNodeSocketAction', 'Out')
