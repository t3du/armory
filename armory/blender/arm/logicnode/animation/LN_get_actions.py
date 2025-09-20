from arm.logicnode.arm_nodes import *

class AnimationNode(ArmLogicTreeNode):
    """Returns the actions list of the given object."""
    bl_idname = 'LNAnimationNode'
    bl_label = 'Get Actions'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketObject', 'Object')

        self.add_output('ArmNodeSocketArray', 'Actions', is_var=False)
        self.add_output('ArmIntSocket', 'Length')