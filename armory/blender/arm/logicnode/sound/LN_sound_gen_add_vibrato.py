from arm.logicnode.arm_nodes import *


class SoundGenAddVibratoNode(ArmLogicTreeNode):
    """Sine with vibrato. `addVibrato(frequency, duration, lfoRate, lfoDepth)`.

    @input In: Append the vibrato tone.
    @input SoundGen: SoundGen from SoundGen New.
    @input Frequency: Carrier Hz. Default 440.
    @input Duration: Seconds. Default 1.
    @input LFO Rate: Vibrato speed in Hz. Default 5.
    @input LFO Depth: Frequency deviation in Hz. Default 10.

    @output Out: Activated after the tone is appended.
    @output SoundGen: Same generator, for chaining.
    """
    bl_idname = 'LNSoundGenAddVibratoNode'
    bl_label = 'SoundGen Add Vibrato'
    arm_section = 'gen-add'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmDynamicSocket', 'SoundGen')
        self.add_input('ArmFloatSocket', 'Frequency', default_value=440.0)
        self.add_input('ArmFloatSocket', 'Duration', default_value=1.0)
        self.add_input('ArmFloatSocket', 'LFO Rate', default_value=5.0)
        self.add_input('ArmFloatSocket', 'LFO Depth', default_value=10.0)

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmDynamicSocket', 'SoundGen')
