from arm.logicnode.arm_nodes import *


class SoundGenPauseNode(ArmLogicTreeNode):
    """Pauses playback. `pause()`.

    @input In: Pause.
    @input SoundGen: The generator that was played.

    @output Out: Activated after pause().
    @output SoundGen: Same generator.
    """
    bl_idname = 'LNSoundGenPauseNode'
    bl_label = 'SoundGen Pause'
    arm_section = 'gen-control'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmDynamicSocket', 'SoundGen')

        self.add_output('ArmNodeSocketAction', 'Out')
