from arm.logicnode.arm_nodes import *

class AddPhysicsHookNode(ArmLogicTreeNode):
    bl_idname = 'AddPhysicsHookNode'
    bl_label = 'Add Physics Hook'
    arm_version = 1

    def init(self, context):
        self.inputs.new('ArmNodeSocketAction', 'In')
        self.inputs.new('ArmNodeSocketObject', 'Object')
        self.inputs.new('ArmNodeSocketObject', 'Target')
        self.inputs.new('ArmNodeSocketArray', 'Vertices (Float)')
        self.outputs.new('ArmNodeSocketAction', 'Out')