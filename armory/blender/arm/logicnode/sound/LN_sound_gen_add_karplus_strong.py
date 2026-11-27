from arm.logicnode.arm_nodes import *


class SoundGenAddKarplusStrongNode(ArmLogicTreeNode):
    """Plucked-string burst. `addKarplusStrong(frequency, duration)`.

    @input In: Append the Karplus-Strong burst.
    @input SoundGen: SoundGen from SoundGen New.
    @input Frequency: Hz. Default 440.
    @input Duration: Seconds. Default 1.

    @output Out: Activated after the burst is appended.
    @output SoundGen: Same generator, for chaining.
    """
    bl_idname = 'LNSoundGenAddKarplusStrongNode'
    bl_label = 'SoundGen Add Karplus Strong'
    arm_section = 'gen-add'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmDynamicSocket', 'SoundGen')
        self.add_input('ArmFloatSocket', 'Frequency', default_value=440.0)
        self.add_input('ArmFloatSocket', 'Duration', default_value=1.0)

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmDynamicSocket', 'SoundGen')