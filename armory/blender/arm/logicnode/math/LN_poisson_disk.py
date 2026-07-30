from arm.logicnode.arm_nodes import *

class PoissonDiskNode(ArmLogicTreeNode):
    """
    Generates an array of points with a poisson distribution.

    SampleCube (Sample Rectangle):
    topLeft: Minimum bounding corner position.
    lowerRight: Maximum bounding corner position.
    minimumDistance: Minimum required spatial distance between points.
    pointsPerIteration: Candidate sample attempts per active point before rejection.

    SampleSphere (Sample Circle):
    center: Sphere center position vector.
    radius: Bounding sphere radius.
    minimumDistance: Minimum required spatial distance between points.
    pointsPerIteration: Candidate sample attempts per active point before rejection.
    """
    bl_idname = 'LNPoissonDiskNode'
    bl_label = 'Poisson Disk Sampling'
    arm_section = 'generator'
    arm_version = 1

    def remove_extra_inputs(self, context):
        while len(self.inputs) > 3:
            self.inputs.remove(self.inputs[-1])
        if self.property0 in ('Sample Cube', 'Sample Rectangle'):
            self.add_input('ArmVectorSocket', 'Top Left')
            self.add_input('ArmVectorSocket', 'Lower Right')
        else:
            self.add_input('ArmVectorSocket', 'Center')
            self.add_input('ArmFloatSocket', 'Radius')

    property0: HaxeEnumProperty(
        'property0',
        items = [('Sample Cube', 'Sample Cube', 'Sample Cube'),
                 ('Sample Sphere', 'Sample Sphere', 'Sample Sphere'),
                 ('Sample Rectangle', 'Sample Rectangle', 'Sample Rectangle'),
                 ('Sample Circle', 'Sample Circle', 'Sample Circle')],
        name='', default='Sample Cube', update=remove_extra_inputs)

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmIntSocket', 'Points Per Iteration')
        self.add_input('ArmFloatSocket', 'Minimum Distance')
        self.add_input('ArmVectorSocket', 'Top Left')
        self.add_input('ArmVectorSocket', 'Lower Right')

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmNodeSocketArray', 'Points')
        self.add_output('ArmIntSocket', 'Length')

    def draw_buttons(self, context, layout):
        layout.prop(self, 'property0')
