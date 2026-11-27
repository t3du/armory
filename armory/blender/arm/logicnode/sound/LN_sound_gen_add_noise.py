from arm.logicnode.arm_nodes import *


class SoundGenAddNoiseNode(ArmLogicTreeNode):
    """Appends white noise. `addNoise(duration)`.

    @input In: Append the noise.
    @input SoundGen: SoundGen from SoundGen New.
    @input Duration: Seconds. Default 0.5.

    @output Out: Activated after the noise is appended.
    @output SoundGen: Same generator, for chaining.
    """
    bl_idname = 'LNSoundGenAddNoiseNode'
    bl_label = 'SoundGen Add Noise'
    arm_section = 'gen-add'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmDynamicSocket', 'SoundGen')
        self.add_input('ArmFloatSocket', 'Duration', default_value=1.0)

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmDynamicSocket', 'SoundGen')
