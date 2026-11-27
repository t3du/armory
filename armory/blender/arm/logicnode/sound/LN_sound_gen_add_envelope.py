from arm.logicnode.arm_nodes import *


class SoundGenAddEnvelopeNode(ArmLogicTreeNode):
    """Sine with an ADSR envelope. `addEnvelope(frequency, duration, attack, decay, sustain, release)`.

    @input In: Append the enveloped tone.
    @input SoundGen: SoundGen from SoundGen New.
    @input Frequency: Hz. Default 440.
    @input Duration: Seconds. Default 1.5.
    @input Attack: Seconds. Default 0.1.
    @input Decay: Seconds. Default 0.2.
    @input Sustain: Level from 0 to 1. Default 0.7.
    @input Release: Seconds. Default 0.3.

    @output Out: Activated after the tone is appended.
    @output SoundGen: Same generator, for chaining.
    """
    bl_idname = 'LNSoundGenAddEnvelopeNode'
    bl_label = 'SoundGen Add Envelope'
    arm_section = 'gen-add'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmDynamicSocket', 'SoundGen')
        self.add_input('ArmFloatSocket', 'Frequency', default_value=440.0)
        self.add_input('ArmFloatSocket', 'Duration', default_value=1.0)
        self.add_input('ArmFloatSocket', 'Attack', default_value=0.1)
        self.add_input('ArmFloatSocket', 'Decay', default_value=0.2)
        self.add_input('ArmFloatSocket', 'Sustain', default_value=0.7)
        self.add_input('ArmFloatSocket', 'Release', default_value=0.3)

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmDynamicSocket', 'SoundGen')
