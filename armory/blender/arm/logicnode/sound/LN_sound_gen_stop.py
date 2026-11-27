from arm.logicnode.arm_nodes import *


class SoundGenStopNode(ArmLogicTreeNode):
    """Stops playback. `stop()`.

    @input In: Stop.
    @input SoundGen: The generator that was played.

    @output Out: Activated after stop().
    @output SoundGen: Same generator.
    """
    bl_idname = 'LNSoundGenStopNode'
    bl_label = 'SoundGen Stop'
    arm_section = 'gen-control'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmDynamicSocket', 'SoundGen')

        self.add_output('ArmNodeSocketAction', 'Out')