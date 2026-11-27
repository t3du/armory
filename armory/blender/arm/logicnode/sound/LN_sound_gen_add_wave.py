from arm.logicnode.arm_nodes import *


class SoundGenAddWaveNode(ArmLogicTreeNode):
    """Appends a wave. `addWave(waveType, frequency, duration)`.

    Wave Type accepts `sine`, `square`, `sawtooth` or `triangle`. Any other
    string is rendered as sine.

    @input In: Append the wave.
    @input SoundGen: SoundGen from SoundGen New.
    @input Wave Type: sine, square, sawtooth or triangle. Default square.
    @input Frequency: Hz. Default 440.
    @input Duration: Seconds. Default 1.

    @output Out: Activated after the wave is appended.
    @output SoundGen: Same generator, for chaining.
    """
    bl_idname = 'LNSoundGenAddWaveNode'
    bl_label = 'SoundGen Add Wave'
    arm_section = 'gen-add'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmDynamicSocket', 'SoundGen')
        self.add_input('ArmIntSocket', '0/1/2/3 = Square/sawtooth/Triangle/Sine')
        self.add_input('ArmFloatSocket', 'Frequency', default_value=440.0)
        self.add_input('ArmFloatSocket', 'Duration', default_value=1.0)

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmDynamicSocket', 'SoundGen')
