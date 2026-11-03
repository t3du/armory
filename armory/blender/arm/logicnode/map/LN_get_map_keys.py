from arm.logicnode.arm_nodes import *


class GetMapKeysNode(ArmLogicTreeNode):
    """Returns an array of all keys in the given map and the number of keys.

    @input Map: Map to get the keys from.

    @output Keys: Array of keys.
    @output Length: The number of keys in the map.
    """

    bl_idname = 'LNGetMapKeysNode'
    bl_label = 'Get Map Keys'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmDynamicSocket', 'Map')

        self.add_output('ArmNodeSocketArray', 'Keys')
        self.add_output('ArmIntSocket', 'Length')

