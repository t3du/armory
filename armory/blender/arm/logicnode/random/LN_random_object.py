from arm.logicnode.arm_nodes import *

class RandomObjectNode(ArmLogicTreeNode):
    """Spawns a random object."""

    bl_idname = 'LNRandomObjectNode'
    bl_label = 'Random Object'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmStringSocket', 'Name')
        self.add_input('ArmDynamicSocket', 'Transform')
        self.add_input('ArmDynamicSocket', 'Material')
        self.add_input('ArmIntSocket', 'NumPoints', default_value = 4)
        self.add_input('ArmBoolSocket', 'Mirror X')
        self.add_input('ArmBoolSocket', 'Mirror Y')
        self.add_input('ArmBoolSocket', 'Mirror Z')
        self.add_input('ArmFloatSocket', 'Scale UV', default_value = 0.3)
        self.add_input('ArmBoolSocket', 'Flat Shading', default_value = True)


        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmNodeSocketObject', 'Object')
