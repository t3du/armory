from arm.logicnode.arm_nodes import *

class GetTransformNode(ArmLogicTreeNode):
    """Returns the transformation of the given object. An object's
    transform consists of vectors describing its global location,
    rotation and scale."""
    bl_idname = 'LNGetTransformNode'
    bl_label = 'Get Object Transform'
    arm_version = 2

    def arm_init(self, context):
        self.add_input('ArmNodeSocketObject', 'Object')
        self.add_input('ArmBoolSocket', 'Parent Relative')

        self.add_output('ArmDynamicSocket', 'Transform')

    def get_replacement_node(self, node_tree: bpy.types.NodeTree):
        if self.arm_version not in (0, 1):
            raise LookupError()
            
        return NodeReplacement.Identity(self)
