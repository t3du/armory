from arm.logicnode.arm_nodes import *

class SetWorldProbeNode(ArmLogicTreeNode):
    """Sets the World Probe of the active scene."""

    bl_idname = 'LNSetWorldProbeNode'
    bl_label = 'Set World Probe'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketAction', 'Reset')
        self.add_input('ArmStringSocket', 'World')

        self.add_output('ArmNodeSocketAction', 'Out')
