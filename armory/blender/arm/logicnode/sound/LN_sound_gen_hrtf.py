from arm.logicnode.arm_nodes import *


class SoundGenHRTFNode(ArmLogicTreeNode):
    """Constant-power pan plus an ITD delay from a camera.
    `playHRTFPanner(camera, soundPos)`.

    Replaces `kha.audio2.Audio.audioCallback`. Call SoundGen Generate first.
    The position is copied so the node does not mutate the plugged-in vector
    (`Vec4.sub` writes in place).

    @input In: Install the panner callback.
    @input SoundGen: SoundGen after SoundGen Generate.
    @input Camera: Camera object.
    @input Position: Sound position in world space. Default (0, 0, 0).

    @output Out: Activated after the call (even if it was skipped).
    @output SoundGen: Same generator.
    """
    bl_idname = 'LNSoundGenHRTFNode'
    bl_label = 'SoundGen HRTF'
    arm_section = 'gen-filter'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmDynamicSocket', 'SoundGen')
        self.add_input('ArmNodeSocketObject', 'Camera')
        self.add_input('ArmVectorSocket', 'Position')

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmNodeSocketAction', 'Done')