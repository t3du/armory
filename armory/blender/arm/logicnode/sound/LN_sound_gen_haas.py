from arm.logicnode.arm_nodes import *


class SoundGenHaasNode(ArmLogicTreeNode):
    """Stereo Haas delay. `playHaasDSP(delayMs)`.

    Replaces `kha.audio2.Audio.audioCallback`. The dry signal stays on the
    left channel and a delayed copy goes to the right. Call SoundGen
    Generate first.

    The function has no default. The socket default is 10 ms.

    @input In: Install the Haas callback.
    @input SoundGen: SoundGen after SoundGen Generate.
    @input Delay: Milliseconds. Default 10. Values below one sample are
        raised to one sample by SoundGenerator.

    @output Out: Activated after the callback is installed.
    @output SoundGen: Same generator.
    """
    bl_idname = 'LNSoundGenHaasNode'
    bl_label = 'SoundGen Haas'
    arm_section = 'gen-filter'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmDynamicSocket', 'SoundGen')
        self.add_input('ArmFloatSocket', 'Delay', default_value=10.0)

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmNodeSocketAction', 'Done')
