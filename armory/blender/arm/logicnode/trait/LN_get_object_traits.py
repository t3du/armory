from arm.logicnode.arm_nodes import *

class GetObjectTraitsNode(ArmLogicTreeNode):
    """Returns all traits from the given object."""
    bl_idname = 'LNGetObjectTraitsNode'
    bl_label = 'Get Object Traits'
    arm_version = 2

    def arm_init(self, context):
        self.add_input('ArmNodeSocketObject', 'Object')

        self.add_output('ArmNodeSocketArray', 'Traits')
        self.add_output('ArmIntSocket', 'Length')

    def get_replacement_node(self, node_tree: bpy.types.NodeTree):    
        return NodeReplacement.Identity(self)
