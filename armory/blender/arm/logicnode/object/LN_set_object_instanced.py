from arm.logicnode.arm_nodes import *

class SetObjectInstancedNode(ArmLogicTreeNode):
    """Sets the object instanced from an array of LOC, ROT and SCL."""
    bl_idname = 'LNSetObjectInstancedNode'
    bl_label = 'Set Object Instanced'
    arm_version = 1

    property0: HaxeEnumProperty(
    'property0',
    items = [('1', 'Loc', 'Instances use their unique position (ipos)'),
             ('2', 'Loc + Rot', 'Instances use their unique position and rotation (ipos and irot)'),
             ('3', 'Loc + Scale', 'Instances use their unique position and scale (ipos and iscl)'),
             ('4', 'Loc + Rot + Scale', 'Instances use their unique position, rotation and scale (ipos, irot, iscl)')],
    name='', default='1', update='')

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Object')
        self.add_input('ArmNodeSocketArray', 'Array Instanced')
        self.add_input('ArmBoolSocket', 'Include original', default_value=True)


        self.add_output('ArmNodeSocketAction', 'Out')

    def draw_buttons(self, context, layout):
        layout.prop(self, 'property0')
