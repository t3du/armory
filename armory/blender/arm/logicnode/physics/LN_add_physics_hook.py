from arm.logicnode.arm_nodes import *

class AddPhysicsHookNode(ArmLogicTreeNode):
    bl_idname = 'LNAddPhysicsHookNode'
    bl_label = 'Add Physics Hook'
    arm_version = 1

    def init(self, context):
        self.inputs.new('ArmNodeSocketAction', 'In')
        self.inputs.new('ArmNodeSocketObject', 'Object')
        self.inputs.new('ArmNodeSocketObject', 'Hook')
        self.inputs.new('ArmNodeSocketArray', 'Vertices')
        self.outputs.new('ArmNodeSocketAction', 'Out')