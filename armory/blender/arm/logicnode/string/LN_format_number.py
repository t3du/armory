from arm.logicnode.arm_nodes import *

class FormatNumberNode(ArmLogicTreeNode):
    bl_idname = 'LNFormatNumberNode'
    bl_label = 'Format Number'
    arm_section = 'util'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmFloatSocket', 'Number', default_value=0.0)
        self.add_input('ArmStringSocket', 'Thousands Sep', default_value=".")
        self.add_input('ArmStringSocket', 'Decimal Sep', default_value=",")
        self.add_input('ArmBoolSocket', 'Include Symbol $', default_value=False)
        self.add_output('ArmStringSocket', 'Result')