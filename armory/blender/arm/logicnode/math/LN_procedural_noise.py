from arm.logicnode.arm_nodes import *

class ProceduralNoiseNode(ArmLogicTreeNode):
    """
    Generates different kind of noises values.

    repeat: Periodicity interval for seamless tiling. -1 disables repeating.

    Perlin:
    x: Spatial X coordinate.
    y: Spatial Y coordinate.
    z: Spatial Z coordinate.

    OctavePerlin:
    x, y, z: Spatial coordinates.
    octaves: Number of noise layers combined.
    persistence: Amplitude multiplier per octave (decay factor).
    frequency: Base spatial scaling factor.

    DiamondSquare:
    width: Total grid width.
    height: Total grid height.
    featureSize: Initial step size for grid subdivision.
    scale: Random offset amplitude scale factor.
    randFunc: Random number generator function returning a Float.
    """
    bl_idname = 'LNProceduralNoiseNode'
    bl_label = 'Procedural Noise'
    arm_section = 'generator'
    arm_version = 1

    def remove_extra_inputs(self, context):
        while len(self.inputs) > 1:
            self.inputs.remove(self.inputs[-1])
        if self.property0 in ('Perlin', 'Octave Perlin'):
            self.add_input('ArmFloatSocket', 'X')
            self.add_input('ArmFloatSocket', 'Y')
            self.add_input('ArmFloatSocket', 'Z')
            self.add_input('ArmIntSocket', 'Repeat', default_value = -1)
        if self.property0 == 'Octave Perlin':
            self.add_input('ArmIntSocket', 'Octaves', default_value = 4)
            self.add_input('ArmFloatSocket', 'Persistence', default_value = 0.5)
            self.add_input('ArmFloatSocket', 'Frequency', default_value = 1.0)
        if self.property0 == 'Diamond Square':
            self.add_input('ArmIntSocket', 'X')
            self.add_input('ArmIntSocket', 'Y')
            self.add_input('ArmIntSocket', 'Width', default_value = 3)
            self.add_input('ArmIntSocket', 'Height', default_value = 3)
            self.add_input('ArmIntSocket', 'Feature Size', default_value = 2)
            self.add_input('ArmFloatSocket', 'Scale', default_value = 1.0)
            self.add_input('ArmFloatSocket', 'Offset', default_value = 0.5)

    property0: HaxeEnumProperty(
        'property0',
        items = [('Perlin', 'Perlin', 'Perlin 3D'),
                 ('Octave Perlin', 'Octave Perlin', 'Octave Perlin 3D'),
                 ('Diamond Square', 'Diamond Square', 'Diamond Square 2D')],
        name='', default='Perlin', update=remove_extra_inputs)

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmFloatSocket', 'X')
        self.add_input('ArmFloatSocket', 'Y')
        self.add_input('ArmFloatSocket', 'Z')
        self.add_input('ArmIntSocket', 'Repeat', default_value = -1)

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmFloatSocket', 'Value')

    def draw_buttons(self, context, layout):
        layout.prop(self, 'property0')
