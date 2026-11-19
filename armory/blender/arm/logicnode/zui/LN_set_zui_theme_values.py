from arm.logicnode.arm_nodes import *


class SetZuiThemeValuesNode(ArmLogicTreeNode):
    """
    NAME: name of the theme.
    BG_COL: WINDOW_BG_COL, SEPARATOR_COL, CONTEXT_COL and PANEL_BG_COL
    WINDOW_BG_COL: window background color.
    WINDOW_TINT_COL: tint color applied when drawing the window texture.
    ACCENT_COL: base accent color for controls and scrollbars.
    ACCENT_HOVER_COL: accent color on mouse hover.
    ACCENT_SELECT_COL: accent color for selected or highlighted elements.
    BUTTON_COL: base color for buttons and unselected tabs.
    BUTTON_TEXT_COL: text color for buttons and active tabs.
    BUTTON_HOVER_COL: color for buttons and tabs on hover or press.
    BUTTON_PRESSED_COL: color for pressed buttons.
    TEXT_COL: primary text color and color for graphics like arrows and cursors.
    LABEL_COL: color for labels and secondary or inactive text.
    SEPARATOR_COL: color for separators, draggable headers, tab backgrounds, and combo dropdowns.
    HIGHLIGHT_COL: highlight color, such as the active tab indicator.
    CONTEXT_COL: contextual color defined in the theme.
    PANEL_BG_COL: panel background color.
    FONT_SIZE: base font size.
    ELEMENT_W: base width for elements, vertical tabs, and horizontal columns.
    ELEMENT_H: base height for UI elements.
    ELEMENT_OFFSET: vertical or horizontal spacing between elements.
    ARROW_SIZE: size of indicator arrows in panels and combos.
    BUTTON_H: base height for buttons, text inputs, sliders, and tabs.
    CHECK_SIZE: outer size of checkboxes and radio buttons.
    CHECK_SELECT_SIZE: inner indicator size for checked boxes and selected radio buttons.
    SCROLL_W: width of the scrollbar.
    TEXT_OFFSET: inner horizontal margin for text.
    TAB_W: indentation width.
    FILL_WINDOW_BG: fills the entire window texture with the background color if true.
    FILL_BUTTON_BG: fills button backgrounds if true.
    FILL_ACCENT_BG: fills accent-colored control backgrounds if true.
    LINK_STYLE: link style defined in the theme (Line or CubicBezier).
    FULL_TABS: makes tabs span the full available width or height if true.
    """
    bl_idname = 'LNSetZuiThemeValuesNode'
    bl_label = 'Set Theme Values'
    arm_section = 'default'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmDynamicSocket', 'UI')
        self.add_input('ArmColorSocket', 'BG_COL', default_value=[0.160784, 0.160784, 0.160784, 1.0])
        self.add_input('ArmColorSocket', 'ACCENT_COL', default_value=[0.223529, 0.223529, 0.223529, 1.0])
        self.add_input('ArmColorSocket', 'ACCENT_HOVER_COL', default_value=[0.262745, 0.262745, 0.262745, 1.0])
        self.add_input('ArmColorSocket', 'ACCENT_SELECT_COL', default_value=[0.313725, 0.313725, 0.313725, 1.0])
        self.add_input('ArmColorSocket', 'BUTTON_COL', default_value=[0.219608, 0.219608, 0.219608, 1.0])
        self.add_input('ArmColorSocket', 'BUTTON_HOVER_COL', default_value=[0.286275, 0.286275, 0.286275, 1.0])
        self.add_input('ArmColorSocket', 'BUTTON_PRESSED_COL', default_value=[0.105882, 0.105882, 0.105882, 1.0])
        self.add_input('ArmColorSocket', 'BUTTON_TEXT_COL', default_value=[0.909804, 0.905882, 0.898039, 1.0])
        self.add_input('ArmColorSocket', 'TEXT_COL', default_value=[0.909804, 0.905882, 0.898039, 1.0])
        self.add_input('ArmColorSocket', 'LABEL_COL', default_value=[0.784314, 0.784314, 0.784314, 1.0])

        self.add_output('ArmNodeSocketAction', 'Out')