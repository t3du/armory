from arm.logicnode.arm_nodes import *


class ZuiImageNode(ArmLogicTreeNode):
    bl_idname = 'LNZuiImageNode'
    bl_label = 'Image'
    arm_section = 'element'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'UI')
        self.add_input('ArmStringSocket', 'Image')
        self.add_input('ArmColorSocket', 'Color', default_value=[1.0, 1.0, 1.0, 1.0])
        self.add_input('ArmFloatSocket', 'Height')
        self.add_input('ArmFloatSocket', 'sX')
        self.add_input('ArmFloatSocket', 'sY')
        self.add_input('ArmFloatSocket', 'sWidth')
        self.add_input('ArmFloatSocket', 'sHeight')

        self.add_output('ArmNodeSocketAction', 'Next')