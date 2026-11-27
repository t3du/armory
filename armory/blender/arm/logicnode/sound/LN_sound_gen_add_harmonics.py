from arm.logicnode.arm_nodes import *


class SoundGenAddHarmonicsNode(ArmLogicTreeNode):
    """Stacked partials. `addHarmonics(frequency, duration, count)`.

    @input In: Append the harmonics.
    @input SoundGen: SoundGen from SoundGen New.
    @input Frequency: Fundamental, Hz. Default 440.
    @input Duration: Seconds. Default 1.
    @input Count: Number of partials. Default 4.

    @output Out: Activated after the harmonics are appended.
    @output SoundGen: Same generator, for chaining.
    """
    bl_idname = 'LNSoundGenAddHarmonicsNode'
    bl_label = 'SoundGen Add Harmonics'
    arm_section = 'gen-add'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmDynamicSocket', 'SoundGen')
        self.add_input('ArmFloatSocket', 'Frequency', default_value=440.0)
        self.add_input('ArmFloatSocket', 'Duration', default_value=1.0)
        self.add_input('ArmIntSocket', 'Count', default_value=4)

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmDynamicSocket', 'SoundGen')