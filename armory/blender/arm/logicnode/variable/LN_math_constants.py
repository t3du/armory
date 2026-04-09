from arm.logicnode.arm_nodes import *

class MathConstantsNode(ArmLogicTreeNode):
    bl_idname = 'LNMathConstantsNode'
    bl_label = 'Math Constants'
    arm_section = 'math'
    arm_version = 1

    def arm_init(self, context):
        self.add_output('ArmFloatSocket', 'Negative Infinity')
        self.add_output('ArmFloatSocket', 'Positive Infinity')
        self.add_output('ArmFloatSocket', 'PI')