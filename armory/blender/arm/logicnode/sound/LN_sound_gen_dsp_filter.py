from arm.logicnode.arm_nodes import *


class SoundGenDSPFilterNode(ArmLogicTreeNode):
    """Plays the generated buffer through a one-pole filter.
    `playDSPFilter(mode, freq1, freq2 = 0)`.

    Replaces `kha.audio2.Audio.audioCallback`. Call SoundGen Generate first.
    Do not use it together with SoundGen Play on the same buffer.

    Mode is `Low`, `High` or `Band`. Anything else outputs silence.
    `freq2` is only used by Band and defaults to 0. Mode and freq1 have no
    defaults; the sockets use `Low` and 440.

    @input In: Install the filter callback and start reading the buffer.
    @input SoundGen: SoundGen after SoundGen Generate.
    @input Mode: Low, High or Band. Default Low.
    @input Frequency 1: Cutoff in Hz. Default 440.
    @input Frequency 2: Band low-pass cutoff in Hz. Default 0.

    @output Out: Activated after the callback is installed.
    @output SoundGen: Same generator.
    """
    bl_idname = 'LNSoundGenDSPFilterNode'
    bl_label = 'SoundGen DSP Filter'
    arm_section = 'gen-filter'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmDynamicSocket', 'SoundGen')
        self.add_input('ArmIntSocket', '0/1/2 = Low/High/Band',)
        self.add_input('ArmFloatSocket', 'Frequency 1', default_value=440.0)
        self.add_input('ArmFloatSocket', 'Frequency 2', default_value=0.0)

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmNodeSocketAction', 'Done')
