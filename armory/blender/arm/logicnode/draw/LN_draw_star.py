from arm.logicnode.arm_nodes import *

class DrawStarNode(ArmLogicTreeNode):
    """Draws a geometric star.

    @input Draw: Activate to draw the star on this frame.
    @input Color: The color of the star.
    @input Filled: Whether the star is filled or outlined.
    @input Strength: The outline thickness.
    @input Points: Number of star points.
    @input Origin X/Origin Y: The center position of the star.
    @input Outer Radius: Distance from center to outer vertices.
    @input Inner Radius: Distance from center to inner vertices.
    @input Rotation: Rotation angle in degrees.

    @output Out: Activated after the star has been drawn.
    """

    bl_idname = 'LNDrawStarNode'
    bl_label = 'Draw Star'
    arm_section = 'draw'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'Draw')
        self.add_input('ArmColorSocket', 'Color', default_value=[1.0, 1.0, 1.0, 1.0])
        self.add_input('ArmBoolSocket', 'Filled')
        self.add_input('ArmFloatSocket', 'Strength', default_value=1.0)
        self.add_input('ArmIntSocket', 'Points', default_value=5)
        self.add_input('ArmFloatSocket', 'X')
        self.add_input('ArmFloatSocket', 'Y')
        self.add_input('ArmFloatSocket', 'Outer Radius', default_value=100.0)
        self.add_input('ArmFloatSocket', 'Inner Radius', default_value=40.0)
        self.add_input('ArmFloatSocket', 'Angle')

        self.add_output('ArmNodeSocketAction', 'Out')