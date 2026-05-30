import bpy

from arm.logicnode.arm_nodes import *


class GroupNode(ArmLogicTreeNode):
    """Returns the objects of the given collection as an array.

    @seeNode Get Collection"""
    bl_idname = 'LNGroupNode'
    bl_label = 'Collection'
    arm_section = 'collection'
    arm_version = 2

    property0: HaxePointerProperty('property0', name='', type=bpy.types.Collection)

    def arm_init(self, context):
        self.add_output('ArmNodeSocketArray', 'Array')
        self.add_output('ArmIntSocket', 'Length')

    def draw_buttons(self, context, layout):
        layout.prop_search(self, 'property0', bpy.data, 'collections', icon='NONE', text='')

    def get_replacement_node(self, node_tree: bpy.types.NodeTree):    
        return NodeReplacement.Identity(self)