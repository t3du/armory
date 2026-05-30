from arm.logicnode.arm_nodes import *

class SplitStringNode(ArmLogicTreeNode):
    """Splits the given string."""
    bl_idname = 'LNSplitStringNode'
    bl_label = 'Split String'
    arm_version = 2

    def arm_init(self, context):
        self.add_input('ArmStringSocket', 'String')
        self.add_input('ArmStringSocket', 'Split')

        self.add_output('ArmNodeSocketArray', 'Array')

    def get_replacement_node(self, node_tree: bpy.types.NodeTree):    
        return NodeReplacement.Identity(self)