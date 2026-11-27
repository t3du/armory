from arm.logicnode.arm_nodes import *


class SoundGenPlayNode(ArmLogicTreeNode):
    """Plays the generated sound. `play(loop, stream, volume)`.

    Call SoundGen Generate first. Defaults are the function defaults:
    loop false, stream false, volume 1.

    @input In: Start playback.
    @input SoundGen: SoundGen after SoundGen Generate.
    @input Loop: Repeat. Default false.
    @input Stream: Passed through to `Audio.play`. Default false.
    @input Volume: 0 to 1. Default 1.

    @output Out: Activated after play() is called.
    @output SoundGen: Same generator. Branch it into Stop, Pause or Set Volume.

    @seeNode SoundGen Stop
    @seeNode SoundGen Pause
    @seeNode SoundGen Set Volume
    """
    bl_idname = 'LNSoundGenPlayNode'
    bl_label = 'SoundGen Play'
    arm_section = 'gen-control'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmDynamicSocket', 'SoundGen')
        self.add_input('ArmBoolSocket', 'Retrigger')
        self.add_input('ArmBoolSocket', 'Loop')
        self.add_input('ArmBoolSocket', 'Stream')
        self.add_input('ArmFloatSocket', 'Volume', default_value=1.0)

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmNodeSocketAction', 'Done')
