from arm.logicnode.arm_nodes import *

class GoToLocationNode(ArmLogicTreeNode):
    """Makes a NavCrowd agent go to location.

    @input In: Start navigation.
    @input Object: The object to navigate. Object must have `NavCrowd` trait applied.
    @input Location: Closest point on the navmesh to navigate to.
    """
    bl_idname = 'LNCrowdGoToLocationNode'
    bl_label = 'Crowd Go to Location'
    arm_section = 'crowd'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmStringSocket', 'NavMeshId', default_value = 'NavMesh')
        self.add_input('ArmNodeSocketObject', 'Object')
        self.add_input('ArmVectorSocket', 'Location')
        self.add_input('ArmFloatSocket', 'Max Speed', 5.0)
        self.add_input('ArmFloatSocket', 'Max Accelaration', 100)
        self.add_input('ArmFloatSocket', 'Turn Speed', 0.1)

        self.add_output('ArmNodeSocketAction', 'Out')

