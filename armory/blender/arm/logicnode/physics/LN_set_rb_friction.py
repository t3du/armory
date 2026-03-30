from arm.logicnode.arm_nodes import *

class SetFrictionNode (ArmLogicTreeNode):
    """Sets the friction of the given rigid body."""
    bl_idname = 'LNSetFrictionNode'
    bl_label = 'Set RB Friction'
    bl_icon = 'NONE'
    arm_version = 1

    def arm_init(self, context):
        self.inputs.new('ArmNodeSocketAction', 'In')
        self.inputs.new('ArmNodeSocketObject', 'RB')
        self.inputs.new('ArmFloatSocket', 'Friction', default_value=0.5)
        self.add_input('ArmFloatSocket', 'Angular Friction', default_value=0.1)

        self.outputs.new('ArmNodeSocketAction', 'Out')
