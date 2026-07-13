from arm.logicnode.arm_nodes import *

class GetObjectCameraDataNode(ArmLogicTreeNode):
    """Returns the camera data of the given object."""
    bl_idname = 'LNGetObjectCameraDataNode'
    bl_label = 'Get Object Camera Data'
    arm_section = 'props'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketObject', 'Object')

        self.add_output('ArmFloatSocket', 'Camera Distance')
        self.add_output('ArmFloatSocket', 'Screen Size')