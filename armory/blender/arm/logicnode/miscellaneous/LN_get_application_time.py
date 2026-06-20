from arm.logicnode.arm_nodes import *

class TimeNode(ArmLogicTreeNode):
    """Returns the application execution time and the delta time."""
    bl_idname = 'LNTimeNode'
    bl_label = 'Get Application Time'
    arm_version = 2

    def arm_init(self, context):
        self.add_output('ArmFloatSocket', 'Time')
        self.add_output('ArmFloatSocket', 'Delta')
        self.add_output('ArmFloatSocket', 'RealTime')


    def get_replacement_node(self, node_tree: bpy.types.NodeTree):
        if self.arm_version not in (1):
            raise LookupError()
            
        return NodeReplacement.Identity(self)
