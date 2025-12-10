from arm.logicnode.arm_nodes import *

class AroundNavigableLocationNode(ArmLogicTreeNode):
    """A random around a navigable location in the navmesh."""
    bl_idname = 'LNAroundNavigableLocationNode'
    bl_label = 'Around NavMesh Location'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmVectorSocket', 'Position')
        self.add_input('ArmFloatSocket', 'Radius')

        self.add_output('ArmVectorSocket', 'Location')
