from arm.logicnode.arm_nodes import *

class GetObjectCameraDistanceNode(ArmLogicTreeNode):
    """Returns the camera distance of the given object."""
    bl_idname = 'LNGetObjectCameraDistanceNode'
    bl_label = 'Get Object Camera Distance'
    arm_section = 'props'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketObject', 'Object')

        self.add_output('ArmFloatSocket', 'Camera Distance')
