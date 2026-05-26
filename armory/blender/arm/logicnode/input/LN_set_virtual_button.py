from arm.logicnode.arm_nodes import *

class SetVirtualButtonNode(ArmLogicTreeNode):
    bl_idname = 'LNSetVirtualButtonNode'
    bl_label = 'Set Virtual Button'
    arm_version = 1

    property0: bpy.props.EnumProperty(
        items=[('Keyboard', 'Keyboard', 'Keyboard'),
               ('Mouse', 'Mouse', 'Mouse'),
               ('Gamepad', 'Gamepad', 'Gamepad')],
        name='Input',
        default='Keyboard'
    )
    property1: bpy.props.StringProperty(name='Virtual Button', default='')
    property2: bpy.props.StringProperty(name='Physical Button', default='')

    def init(self, context):
        self.inputs.new('ArmNodeSocketAction', 'In')
        self.outputs.new('ArmNodeSocketAction', 'Out')

    def draw_buttons(self, context, layout):
        layout.prop(self, 'property0')
        layout.prop(self, 'property1')
        layout.prop(self, 'property2')