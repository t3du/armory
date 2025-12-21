from arm.logicnode.arm_nodes import *

class CrowdSetLocationNode(ArmLogicTreeNode):
    """Makes a NavCrowd agent go to location.

    @input In: Start teleport.
    @input Object: The object to navigate. Object must have `NavCrowd` trait applied.
    @input Location: Closest point on the navmesh to navigate to.
    """
    bl_idname = 'LNCrowdSetLocationNode'
    bl_label = 'Crowd Set Location'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Object')
        self.add_input('ArmVectorSocket', 'Location')

        self.add_output('ArmNodeSocketAction', 'Out')

