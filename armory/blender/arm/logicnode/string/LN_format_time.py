from arm.logicnode.arm_nodes import *

class FormatTimeNode(ArmLogicTreeNode):
    bl_idname = 'LNFormatTimeNode'
    bl_label = 'Format Time'
    arm_section = 'util'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmFloatSocket', 'Time', default_value=0.0)
        self.add_input('ArmStringSocket', 'Format', default_value="HH:MM:SS:MS")
        self.add_output('ArmStringSocket', 'Result')