from arm.logicnode.arm_nodes import *


class SoundGenSetPitchNode(ArmLogicTreeNode):
    """Scales the sound sample rate. `setPitch(pitch)`.

    @input In: Apply the pitch.
    @input SoundGen: SoundGen after SoundGen Generate.
    @input Pitch: Sample-rate multiplier. Default 1.

    @output Out: Activated after setPitch().
    @output SoundGen: Same generator.
    """
    bl_idname = 'LNSoundGenSetPitchNode'
    bl_label = 'SoundGen Set Pitch'
    arm_section = 'gen-control'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmDynamicSocket', 'SoundGen')
        self.add_input('ArmFloatSocket', 'Pitch', default_value=1.0)

        self.add_output('ArmNodeSocketAction', 'Out')