from arm.logicnode.arm_nodes import *


class SoundGenAddSweepNode(ArmLogicTreeNode):
    """Exponential frequency sweep with a continuous phase. `addSweep(startFreq, endFreq, duration)`.

    @input In: Append the sweep.
    @input SoundGen: SoundGen from SoundGen New.
    @input Start Frequency: Hz. Default 200.
    @input End Frequency: Hz. Default 800.
    @input Duration: Seconds. Default 1.

    @output Out: Activated after the sweep is appended.
    @output SoundGen: Same generator, for chaining.

    @seeNode SoundGen Add Bridge
    """
    bl_idname = 'LNSoundGenAddSweepNode'
    bl_label = 'SoundGen Add Sweep'
    arm_section = 'gen-add'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmDynamicSocket', 'SoundGen')
        self.add_input('ArmFloatSocket', 'Start Frequency', default_value=200.0)
        self.add_input('ArmFloatSocket', 'End Frequency', default_value=800.0)
        self.add_input('ArmFloatSocket', 'Duration', default_value=1.0)

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmDynamicSocket', 'SoundGen')
