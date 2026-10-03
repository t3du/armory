from arm.logicnode.arm_nodes import *


class DrawStyledStringNode(ArmLogicTreeNode):
    """Draws a string filled with an image texture.

    @input Draw: Activate to draw the string on this frame. The input must
        be (indirectly) called from an `On Render2D` node.
    @input String: The string to draw.
    @input Image File: The filename (or Image object) of the texture to fill the text with.
    @input Font File: The filename of the font (including the extension).
        If empty and Zui is _enabled_, the default font is used. If empty
        and Zui is _disabled_, nothing is rendered.
    @input Font Size: The size of the font in pixels.
    @input Color: The color tint multiplied with the texture.
    @input X/Y: Position of the string, in pixels from the top left corner.
    @input Angle: Rotation angle in radians. Rectangle will be rotated clockwise
        at the anchor point.
    @input Tile Texture: If true, tiles/repeats the texture across the string. If false, stretches the texture to the text bounds.
    @input Tile Scale: Scaling factor for the texture pattern (default 1.0).
    @input Offset X/Y: Texture offset in pixels, useful for animating the texture.
    @input Border Color: Color of the border outline. Default is black.
    @input Border Size: Border outline thickness in pixels. Default is 0 (no border).

    @output Out: Activated after the string has been drawn.
    @output Width: String Width.
    @output Height: String Height.

    @see [`kha.graphics2.Graphics.drawString()`](http://kha.tech/api/kha/graphics2/Graphics.html#drawString).
    """
    bl_idname = 'LNDrawStyledStringNode'
    bl_label = 'Draw Styled String'
    arm_section = 'draw'
    arm_version = 1

    property1: HaxeEnumProperty(
        'property1',
        items=[('TextLeft', 'Hor. Align. Left', 'Hor. Align. Left'),
               ('TextCenter', 'Hor. Align. Center', 'Hor. Align. Center'),
               ('TextRight', 'Hor. Align. Right', 'Hor. Align. Right'),],
        name='', default='TextLeft')

    property2: HaxeEnumProperty(
        'property2',
        items=[('TextTop', 'Ver. Align. Top', 'Ver. Align. Top'),
               ('TextMiddle', 'Ver. Align. Middle', 'Ver. Align. Middle'),
               ('TextBottom', 'Ver. Align. Bottom', 'Ver. Align. Bottom'),],
        name='', default='TextTop')

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'Draw')
        self.add_input('ArmStringSocket', 'String')
        self.add_input('ArmStringSocket', 'Texture File')
        self.add_input('ArmStringSocket', 'Font File')
        self.add_input('ArmIntSocket', 'Font Size', default_value=16)
        self.add_input('ArmColorSocket', 'Color', default_value=[1.0, 1.0, 1.0, 1.0])
        self.add_input('ArmFloatSocket', 'X')
        self.add_input('ArmFloatSocket', 'Y')
        self.add_input('ArmFloatSocket', 'Angle')
        self.add_input('ArmBoolSocket', 'Tile Texture', default_value=False)
        self.add_input('ArmFloatSocket', 'Tile Scale', default_value=1.0)
        self.add_input('ArmFloatSocket', 'Offset X', default_value=0.0)
        self.add_input('ArmFloatSocket', 'Offset Y', default_value=0.0)
        self.add_input('ArmColorSocket', 'Border Color', default_value=[0.0, 0.0, 0.0, 1.0])
        self.add_input('ArmFloatSocket', 'Border Size', default_value=0.0)

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmFloatSocket', 'Width')
        self.add_output('ArmFloatSocket', 'Height')

    def draw_buttons(self, context, layout):
        layout.prop(self, 'property1')
        layout.prop(self, 'property2')
