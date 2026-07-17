from arm.logicnode.arm_nodes import *

class RandomColorNode(ArmLogicTreeNode):
    """Generates a random color."""
    bl_idname = 'LNRandomColorNode'
    bl_label = 'Random Color'
    arm_version = 2

    property0: HaxeBoolProperty(
        'property0',
        name='R',
        default=True
    )

    property1: HaxeBoolProperty(
        'property1',
        name='G',
        default=True
    )

    property2: HaxeBoolProperty(
        'property2',
        name='B',
        default=True
    )

    property3: HaxeBoolProperty(
        'property3',
        name='A',
        default=False
    )

    property4: HaxeFloatProperty(
        'property4',
        name='R Value',
        default=0.0,
        min=0.0,
        max=1.0
    )

    property5: HaxeFloatProperty(
        'property5',
        name='G Value',
        default=0.0,
        min=0.0,
        max=1.0
    )

    property6: HaxeFloatProperty(
        'property6',
        name='B Value',
        default=0.0,
        min=0.0,
        max=1.0
    )

    property7: HaxeFloatProperty(
        'property7',
        name='A Value',
        default=1.0,
        min=0.0,
        max=1.0
    )


    def arm_init(self, context):
        self.add_output('ArmColorSocket', 'Color')


    def draw_buttons(self, context, layout):

        for flag, value, label in [
            ('property0', 'property4', 'R'),
            ('property1', 'property5', 'G'),
            ('property2', 'property6', 'B'),
            ('property3', 'property7', 'A'),
        ]:
            row = layout.row(align=True)

            row.prop(self, flag, text=label)

            value_row = row.row(align=True)
            value_row.enabled = not getattr(self, flag)
            value_row.prop(self, value, text='')


    def get_replacement_node(self, node_tree):
        if self.arm_version not in (0, 1):
            raise LookupError()

        return NodeReplacement.Identity(self)
