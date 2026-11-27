from arm.logicnode.arm_nodes import *


class SoundGenGenerateNode(ArmLogicTreeNode):
    """Builds the `kha.Sound` from the samples appended so far. `generate()`.

    Required before SoundGen Play, Set Pitch and the DSP nodes.

    @input In: Generate the sound.
    @input SoundGen: SoundGen from SoundGen New, after the Add nodes.

    @output Out: Activated after generation.
    @output SoundGen: Same generator, for chaining.
    @output Sound: The generated `kha.Sound`, or null if SoundGen is missing.

    """
    bl_idname = 'LNSoundGenGenerateNode'
    bl_label = 'SoundGen Generate'
    arm_section = 'gen'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmDynamicSocket', 'SoundGen')

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmDynamicSocket', 'SoundGen')
