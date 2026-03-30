from arm.logicnode.arm_nodes import *

class RemovePhysicsConstraintNode(ArmLogicTreeNode):
    bl_idname = 'RemovePhysicsConstraintNode'
    bl_label = 'Remove Physics Constraint'
    arm_version = 1

    def init(self, context):
        self.inputs.new('ArmNodeSocketAction', 'In')
        self.inputs.new('ArmNodeSocketObject', 'Object')

        self.outputs.new('ArmNodeSocketAction', 'Out')