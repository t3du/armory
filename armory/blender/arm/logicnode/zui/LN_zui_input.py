from arm.logicnode.arm_nodes import *


class ZuiInputNode(ArmLogicTreeNode):
    """Adds a text, multiline, float, or integer input field."""
    bl_idname = 'LNZuiInputNode'
    bl_label = 'Input'
    arm_section = 'element'
    arm_version = 1

    def update_input_type(self, context):
        socket_type = {
            'Text': 'ArmStringSocket',
            'Text Area': 'ArmStringSocket',
            'Float': 'ArmFloatSocket',
            'Integer': 'ArmIntSocket',
        }[self.property0]
        self.change_input_socket(socket_type, 4, 'Initial Value')
        self.change_output_socket(socket_type, 2, 'Value')
        
        if self.property0 == 'Float':
            if len(self.inputs) <= 5:
                self.add_input('ArmFloatSocket', 'Precision', default_value=100)
        elif len(self.inputs) > 5:
            self.inputs.remove(self.inputs[5])


    property0: HaxeEnumProperty(
        'property0',
        items=[('Text', 'Text', 'Single-line text input'),
               ('Text Area', 'Text Area', 'Multiline text input'),
               ('Float', 'Float', 'Floating-point input'),
               ('Integer', 'Integer', 'Whole-number input')],
        name='Type', default='Text', update=update_input_type)

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'UI')
        self.add_input('ArmStringSocket', 'Label', default_value='Input')
        self.add_input('ArmIntSocket', 'Align')
        self.add_input('ArmBoolSocket', 'Editable', default_value=True)
        self.add_input('ArmStringSocket', 'Initial Value')

        self.add_output('ArmNodeSocketAction', 'Changed')
        self.add_output('ArmNodeSocketAction', 'Next')
        self.add_output('ArmStringSocket', 'Value')

    def draw_buttons(self, context, layout):
        layout.prop(self, 'property0')
