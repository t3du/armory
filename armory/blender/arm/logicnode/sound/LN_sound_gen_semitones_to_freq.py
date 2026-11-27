from arm.logicnode.arm_nodes import *


class SoundGenSemitonesToFreqNode(ArmLogicTreeNode):
    """Semitone offset from A4 to Hz. `semitonesToFreq(semitones, baseA4 = 440)`.

    Value node. 0 semitones is A4. Base A4 default is 440. Semitones has no
    default on the function; the socket default is 0.

    @input Semitones: Offset from A4. Default 0.
    @input Base A4: Tuning of A4 in Hz. Default 440.

    @output Frequency: Hz.
    """
    bl_idname = 'LNSoundGenSemitonesToFreqNode'
    bl_label = 'SoundGen Semitones To Freq'
    arm_section = 'gen-get'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmIntSocket', 'Semitones')
        self.add_input('ArmFloatSocket', 'Base A4', default_value=440.0)

        self.add_output('ArmFloatSocket', 'Frequency')
