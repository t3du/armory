from arm.logicnode.arm_nodes import *

class NavigableLocationNode(ArmLogicTreeNode):
    """A random navigable location in the navmesh."""
    bl_idname = 'LNNavigableLocationNode'
    bl_label = 'Random Navigable Location'
    arm_version = 2

    def arm_init(self, context):
        self.add_input('ArmNodeSocketObject', 'NavMesh')

        self.add_output('ArmVectorSocket', 'Location')
