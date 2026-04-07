from arm.logicnode.arm_nodes import *

class RemovePhysicsHookNode(ArmLogicTreeNode):
    bl_idname = 'LNRemovePhysicsHookNode'
    bl_label = 'Remove Physics Hook'
    arm_version = 1

    def init(self, context):
        self.inputs.new('ArmNodeSocketAction', 'In')
        self.inputs.new('ArmNodeSocketObject', 'Object')
        self.outputs.new('ArmNodeSocketAction', 'Out')