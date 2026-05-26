from arm.logicnode.arm_nodes import *

def update_node(self, context):
    if self.property0 == 'Invert':
        self.inputs[1].hide = True
    else:
        self.inputs[1].hide = False

class TransformMathNode(ArmLogicTreeNode):
    """Performs mathematical operations on transformation matrices."""
    bl_idname = 'LNTransformMathNode'
    bl_label = 'Transform Math'
    arm_version = 2

    property0: HaxeEnumProperty(
        'property0',
        items = [
            ('Multiply', 'Multiply', 'Standard matrix multiplication combining position, rotation, and scale'),
            ('Invert', 'Invert', 'Calculates the inverse matrix, reversing all transformations'),
            ('Transform Math', 'Transform Math', 'Multiplies rotation and scale while directly adding translations')
        ],
        name='', default='Multiply', update=update_node)

    def arm_init(self, context):
        self.add_input('ArmDynamicSocket', 'Transform 1')
        self.add_input('ArmDynamicSocket', 'Transform 2')

        self.add_output('ArmDynamicSocket', 'Result')

    def draw_buttons(self, context, layout):
        layout.prop(self, 'property0')