from arm.logicnode.arm_nodes import *

class AddTraitNode(ArmLogicTreeNode):
    """Adds trait to the given object."""
    bl_idname = 'LNAddTraitNode'
    bl_label = 'Add Trait to Object'
    arm_version = 3

    def remove_extra_inputs(self, context):
        if len(self.inputs) > 1:
            self.inputs.remove(self.inputs[-1])
        if self.property0 == 'Trait':
            self.add_input('ArmDynamicSocket', 'Trait')
        else:
            self.add_input('ArmStringSocket', 'TraitName')

    property0: HaxeEnumProperty(
    'property0',
    items = [('Trait', 'Trait', 'Trait'),
             ('TraitName', 'TraitName', 'TraitName')],
    name='', default='TraitName', update=remove_extra_inputs)

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'Object')
        self.add_input('ArmStringSocket', 'TraitName')

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmDynamicSocket', 'Trait')

    def draw_buttons(self, context, layout):
        layout.prop(self, 'property0')

    def get_replacement_node(self, node_tree: bpy.types.NodeTree):
        if self.arm_version not in (0, 2):
            raise LookupError()
            
        return NodeReplacement.Identity(self)