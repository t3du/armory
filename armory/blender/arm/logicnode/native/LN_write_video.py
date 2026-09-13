from arm.logicnode.arm_nodes import *


class WriteVideoNode(ArmLogicTreeNode):
    """Writes the given video to the given file. If the video
    already exists, the existing content of the video is overwritten.
    @seeNode Read File
    """
    bl_idname = 'LNWriteVideoNode'
    bl_label = 'Write Video'
    arm_section = 'file'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'Start')
        self.add_input('ArmNodeSocketAction', 'Stop')
        self.add_input('ArmStringSocket', 'Video File')
        self.add_input('ArmNodeSocketObject', 'Camera')
        self.add_input('ArmIntSocket', 'Width')
        self.add_input('ArmIntSocket', 'Height')
        self.add_input('ArmIntSocket', 'sX')
        self.add_input('ArmIntSocket', 'sY')
        self.add_input('ArmIntSocket', 'sWidth')
        self.add_input('ArmIntSocket', 'sHeight')
        self.add_input('ArmBoolSocket', 'Render2D')
        self.add_input('ArmFloatSocket', 'Frame duration')
        self.add_input('ArmFloatSocket', 'Volume', default_value = 1.0)

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmNodeSocketAction', 'Done')
        self.add_output('ArmIntSocket', 'Total Frames')
        self.add_output('ArmIntSocket', 'Current Frame')