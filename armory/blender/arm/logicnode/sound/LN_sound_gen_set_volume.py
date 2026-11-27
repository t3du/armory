from arm.logicnode.arm_nodes import *


class SoundGenSetVolumeNode(ArmLogicTreeNode):
    """Sets the playing channel volume. `setVolume(volume)`.

    @input In: Apply the volume.
    @input SoundGen: The generator that was played.
    @input Volume: 0 to 1. Default 1.

    @output Out: Activated after setVolume().
    @output SoundGen: Same generator.
    """
    bl_idname = 'LNSoundGenSetVolumeNode'
    bl_label = 'SoundGen Set Volume'
    arm_section = 'gen-control'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmDynamicSocket', 'SoundGen')
        self.add_input('ArmFloatSocket', 'Volume', default_value=1.0)

        self.add_output('ArmNodeSocketAction', 'Out')
