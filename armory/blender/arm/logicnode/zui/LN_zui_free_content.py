from arm.logicnode.arm_nodes import *


class ZuiFreeContentNode(ArmLogicTreeNode):
    bl_idname = 'LNZuiFreeContentNode'
    bl_label = 'UI Free Content'
    arm_section = 'layout'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'Draw')
        self.add_input('ArmDynamicSocket', 'UI')
        self.add_input('ArmFloatSocket', 'X')
        self.add_input('ArmFloatSocket', 'Y')
        self.add_input('ArmIntSocket', 'Width', default_value=300)
        self.add_input('ArmColorSocket', 'BG Color', default_value=[0.160784, 0.160784, 0.160784, 0.0])
        self.add_input('ArmFloatSocket', 'Margin')
        self.add_input('ArmBoolSocket', 'Relative');

        self.add_output('ArmNodeSocketAction', 'Content')
        self.add_output('ArmFloatSocket', 'Center X')
        self.add_output('ArmFloatSocket', 'Center Y')
        self.add_output('ArmFloatSocket', 'Height')
