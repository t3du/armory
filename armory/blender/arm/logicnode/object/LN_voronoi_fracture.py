from arm.logicnode.arm_nodes import *

class VoronoiFractureNode(ArmLogicTreeNode):
    """Generate Voronoi fracture fragments from a mesh."""

    bl_idname = 'LNVoronoiFractureNode'
    bl_label = 'Voronoi Fracture'
    arm_section = 'generate'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Object')
        self.add_input('ArmIntSocket', 'Num Points', default_value=10)
        self.add_input('ArmIntSocket', 'Seed')
        self.add_input('ArmIntSocket', 'Distribution')
        self.add_input('ArmVectorSocket', 'Impact Point')
        self.add_input('ArmFloatSocket', 'Impact Radius', default_value=1.0)
        self.add_input('ArmNodeSocketArray', 'Custom Points')
        self.add_input('ArmDynamicSocket', 'Interior Material')
        self.add_input('ArmFloatSocket', 'Margin')
        self.add_input('ArmBoolSocket', 'Separate Loose Parts')
        self.add_input('ArmBoolSocket', 'Remove Object')

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmNodeSocketArray', 'Objects')


