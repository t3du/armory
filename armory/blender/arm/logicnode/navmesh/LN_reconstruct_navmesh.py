from arm.logicnode.arm_nodes import *

class ReconstructNavMeshNode(ArmLogicTreeNode):
    """Reconstruct a given NavMesh."""
    bl_idname = 'LNReconstructNavMeshNode'
    bl_label = 'Reconstruct NavMesh'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'NavMesh')
        
        self.add_output('ArmNodeSocketAction', 'Out')
