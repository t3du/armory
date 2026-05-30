from arm.logicnode.arm_nodes import *

class GetGroupNode(ArmLogicTreeNode):
    """Searches for a collection of objects with the given name and
    outputs the collection's objects as an array, if found.

    @seeNode Collection"""
    bl_idname = 'LNGetGroupNode'
    bl_label = 'Get Collection'
    arm_section = 'collection'
    arm_version = 2

    def arm_init(self, context):
        self.add_input('ArmStringSocket', 'Name')

        self.add_output('ArmNodeSocketArray', 'Objects')
        self.add_output('ArmIntSocket', 'Length')

    def get_replacement_node(self, node_tree: bpy.types.NodeTree):    
        return NodeReplacement.Identity(self)