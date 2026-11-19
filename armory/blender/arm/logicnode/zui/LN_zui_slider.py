from arm.logicnode.arm_nodes import *


class ZuiSliderNode(ArmLogicTreeNode):
    """Adds a float or integer slider to the current Zui window."""
    bl_idname = 'LNZuiSliderNode'
    bl_label = 'Slider'
    arm_section = 'element'
    arm_version = 1

    def update_value_type(self, context):
        socket_type = 'ArmIntSocket' if self.property0 == 'Integer' else 'ArmFloatSocket'
        self.change_input_socket(socket_type, 2, 'Minimum')
        self.change_input_socket(socket_type, 3, 'Maximum')
        self.change_input_socket(socket_type, 4, 'Initial Value')
        self.change_output_socket(socket_type, 2, 'Value')

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'UI')
        self.add_input('ArmStringSocket', 'Text', default_value='Slider')
        self.add_input('ArmFloatSocket', 'Minimum')
        self.add_input('ArmFloatSocket', 'Maximum', default_value=1.0)
        self.add_input('ArmFloatSocket', 'Initial Value')
        self.add_input('ArmBoolSocket', 'Filled', default_value=False)
        self.add_input('ArmFloatSocket', 'Precision', default_value=100.0)
        self.add_input('ArmBoolSocket', 'Display Value', default_value=True)
        self.add_input('ArmIntSocket', 'Align', default_value=2)
        self.add_input('ArmBoolSocket', 'Text Edit', default_value=True)

        self.add_output('ArmNodeSocketAction', 'Changed')
        self.add_output('ArmNodeSocketAction', 'Next')
        self.add_output('ArmFloatSocket', 'Value')
