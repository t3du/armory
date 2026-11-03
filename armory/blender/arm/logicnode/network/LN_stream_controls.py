from arm.logicnode.arm_nodes import *


class StreamControlsNode(ArmLogicTreeNode):
    """Displays and plays one MediaStream with runtime audio and video controls."""

    bl_idname = 'LNStreamControlsNode'
    bl_label = 'Stream Controls'
    arm_section = 'call'

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'Start')
        self.add_input('ArmNodeSocketAction', 'Stop')
        self.add_input('ArmDynamicSocket', 'Stream')
        self.add_input('ArmStringSocket', 'Title', default_value='Video')
        self.add_input('ArmIntSocket', 'X', default_value=20)
        self.add_input('ArmIntSocket', 'Y', default_value=20)
        self.add_input('ArmIntSocket', 'Width', default_value=320)
        self.add_input('ArmIntSocket', 'Height', default_value=240)
        self.add_input('ArmBoolSocket', 'Video', default_value=True)
        self.add_input('ArmBoolSocket', 'Audio', default_value=True)
         # Custom Styles
        self.add_input('ArmStringSocket', 'Panel Style')
        self.add_input('ArmStringSocket', 'Button Style')
        self.add_input('ArmStringSocket', 'Video Style')

        self.add_output('ArmNodeSocketAction', 'Out')
