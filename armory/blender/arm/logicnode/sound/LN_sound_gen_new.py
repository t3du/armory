from arm.logicnode.arm_nodes import *


class SoundGenNewNode(ArmLogicTreeNode):
    """Creates a Sound Generator

    @input In: Create the generator.
    @input Sampling Rate: Samples per second. Default 44100.
    @input Channels: 1 = mono. Values above 1 duplicate the sample on the
        extra channel. Default 1.
    @input Bits Per Sample: 8 or 16. Other values write no samples. Default 16.

    @output Out: Activated after the generator is created.
    @output SoundGen: Pass this socket into the other SoundGen nodes.
    """
    bl_idname = 'LNSoundGenNewNode'
    bl_label = 'SoundGen New'
    arm_section = 'gen'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmIntSocket', 'Sampling Rate', default_value=44100)
        self.add_input('ArmIntSocket', 'Channels', default_value=1)
        self.add_input('ArmIntSocket', 'Bits Per Sample', default_value=16)

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmDynamicSocket', 'SoundGen')
