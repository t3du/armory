from arm.logicnode.arm_nodes import *

class StopCrowdNode(ArmLogicTreeNode):
    """Stops the given NavMesh agent."""
    bl_idname = 'LNStopCrowdNode'
    bl_label = 'Stop Crowd'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Object')

        self.add_output('ArmNodeSocketAction', 'Out')
