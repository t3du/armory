from arm.logicnode.arm_nodes import *

class DrawString3DNode(ArmLogicTreeNode):
    """Draws a list of 3D lines.

    @input Start: Activate to start drawing every frame.
    @input Stop: Activate to stop drawing.

    @output Out: Activated after Start or Stop is processed.
    """
    bl_idname = 'LNDrawString3DNode'
    bl_label = 'Draw String 3D'
    arm_section = 'draw3d'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'Start')
        self.add_input('ArmNodeSocketAction', 'Stop')
        self.add_input('ArmStringSocket', 'String')
        self.add_input('ArmColorSocket', 'Color', default_value=[1.0, 1.0, 1.0, 1.0])
        self.add_input('ArmIntSocket', '0/1/2: BorderLine/Filled/SingleLine')
        self.add_input('ArmFloatSocket', 'Thickness', default_value=0.1)
        self.add_input('ArmVectorSocket', 'Align', default_value=[0.5, 0.5, 0.0])
        self.add_input('ArmVectorSocket', 'Position')
        self.add_input('ArmRotationSocket', 'Rotation')
        self.add_input('ArmFloatSocket', 'Scale', default_value=1.0)

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmFloatSocket', 'Width')
        self.add_output('ArmFloatSocket', 'Height')