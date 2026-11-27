from arm.logicnode.arm_nodes import *


class SoundGenWriteNode(ArmLogicTreeNode):
    """Writes the sample buffer to a WAV file. `write(file)`.

    Does not need SoundGen Generate (it reads the raw buffer). On Krom the
    file is saved next to the project files; on HTML5 it downloads.

    No default on the function. Socket default is `sound.wav`.

    @input In: Write the file.
    @input SoundGen: SoundGen after the Add nodes.
    @input File: File name. Default sound.wav.

    @output Out: Activated after write().
    @output SoundGen: Same generator.
    """
    bl_idname = 'LNSoundGenWriteNode'
    bl_label = 'SoundGen Write'
    arm_section = 'gen'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmDynamicSocket', 'SoundGen')
        self.add_input('ArmStringSocket', 'File', default_value='sound.wav')

        self.add_output('ArmNodeSocketAction', 'Out')
