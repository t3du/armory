from arm.logicnode.arm_nodes import *

class ConvexBreakNode(ArmLogicTreeNode):
    """Breaks a convex object."""

    bl_idname = 'LNConvexBreakNode'
    bl_label = 'Convex Break'
    arm_version = 1

    def update_sockets(self, context):
        while len(self.inputs) > 2:
            self.inputs.remove(self.inputs[-1])

        if self.property0 == 'Impact':
            self.add_input('ArmVectorSocket', 'Impact Point')
            self.add_input('ArmVectorSocket', 'Impact Normal')
        else:
            self.add_input('ArmBoolSocket', 'Random Plane')
            self.add_input('ArmVectorSocket', 'Plane')
        self.add_input('ArmFloatSocket', 'Scale UV')
        self.add_input('ArmBoolSocket', 'Flat Shading', default_value = True)

    property0: HaxeEnumProperty(
        'property0',
        items = [('Impact', 'Subdivide by Impact', 'Subdivide by Impact'),
                 ('Plane', 'Subdivide by Plane', 'Subdivide by Plane')],
        name='', default='Impact', update=update_sockets)

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Object')
        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmNodeSocketAction', 'True')
        self.add_output('ArmNodeSocketAction', 'False')
        self.add_output('ArmNodeSocketArray', 'Array')
        self.update_sockets(context)

    def draw_buttons(self, context, layout):
        layout.prop(self, 'property0')