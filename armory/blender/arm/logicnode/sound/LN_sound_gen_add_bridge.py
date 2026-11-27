from arm.logicnode.arm_nodes import *


class SoundGenAddBridgeNode(ArmLogicTreeNode):
    """Linear frequency glide. `addBridge(startFreq, endFreq, duration)`.

    Phase is absolute (it can click). Use SoundGen Add Sweep for an
    exponential glide with a continuous phase.

    No defaults on the function. Socket defaults match SoundController:
    440 Hz -> 880 Hz over 2 s.

    @input In: Append the bridge.
    @input SoundGen: SoundGen from SoundGen New.
    @input Start Frequency: Hz. Default 440.
    @input End Frequency: Hz. Default 880.
    @input Duration: Seconds. Default 2.

    @output Out: Activated after the bridge is appended.
    @output SoundGen: Same generator, for chaining.
    """
    bl_idname = 'LNSoundGenAddBridgeNode'
    bl_label = 'SoundGen Add Bridge'
    arm_section = 'gen-add'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmDynamicSocket', 'SoundGen')
        self.add_input('ArmFloatSocket', 'Start Frequency', default_value=440.0)
        self.add_input('ArmFloatSocket', 'End Frequency', default_value=880.0)
        self.add_input('ArmFloatSocket', 'Duration', default_value=1.0)

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmDynamicSocket', 'SoundGen')
