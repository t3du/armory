from arm.logicnode.arm_nodes import *


class DrawVideoNode(ArmLogicTreeNode):
    """
    Container: AVI
    Video: JPEG/MJPEG (MJPG)
    Audio: PCM 16-bit

    """
    bl_idname = 'LNDrawVideoNode'
    bl_label = 'Draw Video'
    arm_section = 'draw'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'Draw')
        self.add_input('ArmStringSocket', 'Video File')
        self.add_input('ArmColorSocket', 'Color', default_value=[1.0, 1.0, 1.0, 1.0])
        self.add_input('ArmIntSocket', '0/1/2 = Left/Center/Right', default_value=0)
        self.add_input('ArmIntSocket', '0/1/2 = Top/Middle/Bottom', default_value=0)
        self.add_input('ArmFloatSocket', 'X')
        self.add_input('ArmFloatSocket', 'Y')
        self.add_input('ArmFloatSocket', 'Width')
        self.add_input('ArmFloatSocket', 'Height')
        self.add_input('ArmFloatSocket', 'sX')
        self.add_input('ArmFloatSocket', 'sY')
        self.add_input('ArmFloatSocket', 'sWidth')
        self.add_input('ArmFloatSocket', 'sHeight')
        self.add_input('ArmFloatSocket', 'Angle')
        self.add_input('ArmIntSocket', 'Start Frame')
        self.add_input('ArmIntSocket', 'End Frame', default_value=-1)
        self.add_input('ArmFloatSocket', 'Volume', default_value = 1.0)
        self.add_input('ArmBoolSocket', 'Loop')

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmIntSocket', 'Total Frames')
        self.add_output('ArmIntSocket', 'Current Frame')