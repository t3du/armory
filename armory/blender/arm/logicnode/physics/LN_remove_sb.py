from arm.logicnode.arm_nodes import *

class RemoveSoftBodyNode(ArmLogicTreeNode):
    bl_idname = 'LNRemoveSoftBodyNode'
    bl_label = 'Remove SB'
    arm_section = 'softbody'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'SB')
        self.add_input('ArmBoolSocket', 'Restore Geom')
        
        self.add_output('ArmNodeSocketAction', 'Out')