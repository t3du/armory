from arm.logicnode.arm_nodes import *

class GetKeyboardNode(ArmLogicTreeNode):
    bl_idname = 'LNGetKeyboardNode'
    bl_label = 'Get Keyboard'
    arm_section = 'keyboard'
    arm_version = 1

    def update(self):
        self.label = f'{self.bl_label}: {self.property0}'

    def upd(self, context):
        self.label = f'{self.bl_label}: {self.property0}'

    property0: HaxeEnumProperty(
        'property0',
        items = [('started', 'Started', 'The keyboard button starts to be pressed'),
                 ('down', 'Down', 'The keyboard button is pressed'),
                 ('released', 'Released', 'The keyboard button stops being pressed')],
        name='', default='started', update=upd)

    def arm_init(self, context):
        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmStringSocket', 'Key')

    def draw_buttons(self, context, layout):
        layout.prop(self, 'property0')

    def draw_label(self) -> str:
        return f'{self.bl_label}: {self.property0}'