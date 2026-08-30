from arm.logicnode.arm_nodes import *

class CurveGuideNode(ArmLogicTreeNode):
    """Sets the curves guide of the given particle source."""
    bl_idname = 'LNCurveGuideNode'
    bl_label = 'Curve Guide'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Object')
        self.add_input('ArmIntSocket', 'Slot')
        self.add_input('ArmNodeSocketArray', 'Curve Array')
        self.add_input('ArmFloatSocket', 'Strengh', default_value = 1.0)
        self.add_input('ArmFloatSocket', 'Speed', default_value = 1.0)

        self.add_output('ArmNodeSocketAction', 'Out')