from arm.logicnode.arm_nodes import *


class SoundGenAddChordNode(ArmLogicTreeNode):
    """Mixes several sines. `addChord(frequencies, duration)`.

    @input In: Append the chord.
    @input SoundGen: SoundGen from SoundGen New.
    @input Frequencies: Array of Hz values. Unconnected = 261.63, 329.63, 392.
    @input Duration: Seconds. Default 1.

    @output Out: Activated after the chord is appended.
    @output SoundGen: Same generator, for chaining.
    """
    bl_idname = 'LNSoundGenAddChordNode'
    bl_label = 'SoundGen Add Chord'
    arm_section = 'gen-add'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmDynamicSocket', 'SoundGen')
        self.add_input('ArmNodeSocketArray', 'Frequencies')
        self.add_input('ArmFloatSocket', 'Duration', default_value=1.0)

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmDynamicSocket', 'SoundGen')
