from arm.logicnode.arm_nodes import *


class SoundGenNoteToFreqNode(ArmLogicTreeNode):
    """MIDI note to Hz. `noteToFreq(midiNote, baseA4 = 440)`.

    Value node: no execution pulse. Output is read by whoever uses it.
    MIDI 69 is A4. Base A4 default is 440.

    @input MIDI Note: Default 69 (A4).
    @input Base A4: Tuning of A4 in Hz. Default 440.

    @output Frequency: Hz.
    """
    bl_idname = 'LNSoundGenNoteToFreqNode'
    bl_label = 'SoundGen Note To Freq'
    arm_section = 'gen-get'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmIntSocket', 'MIDI Note', default_value=69)
        self.add_input('ArmFloatSocket', 'Base A4', default_value=440.0)

        self.add_output('ArmFloatSocket', 'Frequency')