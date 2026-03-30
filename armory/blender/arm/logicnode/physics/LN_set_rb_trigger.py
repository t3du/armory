from arm.logicnode.arm_nodes import *

class SetRigidBodyTriggerNode(ArmLogicTreeNode):
    bl_idname = 'LNSetRigidBodyTriggerNode'
    bl_label = 'Set RB Trigger'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Object')
        self.add_input('ArmBoolSocket', 'Is Trigger', default_value=False)
        self.add_output('ArmNodeSocketAction', 'Out')