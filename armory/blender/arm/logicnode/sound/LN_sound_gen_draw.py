from arm.logicnode.arm_nodes import *


class SoundGenDrawNode(ArmLogicTreeNode):
    """Draws the generated waveform, same as SoundController.addDraw.

    Pulse In from On Render2D is not required: the node registers its own
    render callback. Remove unregisters it.

    Peaks are stored per SoundGen so SoundGen Get Amplitude can read them.
    Call SoundGen Generate before In, or there is nothing to draw.

    @input In: Build the peaks and start drawing.
    @input Remove: Stop drawing.
    @input SoundGen: Generator after SoundGen Generate.
    @input X: Left of the rect, in pixels. Default 0.
    @input Y: Top of the rect, in pixels. Default 0.
    @input Width: Width in pixels. Default 256. Also the peak count.
    @input Height: Height in pixels. Default 64.
    @input Line Color: Playhead. Default white.
    @input Wave Color: Played portion. Default (0.2, 0.75, 1, 1).
    @input Wave Bg Color: Unplayed portion. Default (0.25, 0.25, 0.3, 1).
    @input Bg Color: Background. Default (0.08, 0.08, 0.1, 1).

    @output Out: Activated after Draw.
    """
    bl_idname = 'LNSoundGenDrawNode'
    bl_label = 'SoundGen Draw'
    arm_section = 'gen'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'Draw')
        self.add_input('ArmDynamicSocket', 'SoundGen')
        self.add_input('ArmIntSocket', 'X')
        self.add_input('ArmIntSocket', 'Y')
        self.add_input('ArmIntSocket', 'Width', default_value=256)
        self.add_input('ArmIntSocket', 'Height', default_value=64)
        self.add_input('ArmColorSocket', 'Line Color', default_value=[1.0, 1.0, 1.0, 1.0])
        self.add_input('ArmColorSocket', 'Wave Color', default_value=[0.2, 0.75, 1.0, 1.0])
        self.add_input('ArmColorSocket', 'Wave Bg Color', default_value=[0.25, 0.25, 0.3, 1.0])
        self.add_input('ArmColorSocket', 'Bg Color', default_value=[0.160784, 0.160784, 0.160784, 1.0])

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmIntSocket', 'Length')
        self.add_output('ArmFloatSocket', 'Position')
        self.add_output('ArmFloatSocket', 'Amplitude')
