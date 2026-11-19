from arm.logicnode.arm_nodes import *


class ZuiListNode(ArmLogicTreeNode):
    """Displays and edits a list of strings, optionally with selection radios."""
    bl_idname = 'LNZuiListNode'
    bl_label = 'List'
    arm_section = 'element'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'UI')
        self.add_input('ArmNodeSocketArray', 'Items')
        self.add_input('ArmBoolSocket', 'Editable', default_value=True)
        self.add_input('ArmBoolSocket', 'Show Radio')
        self.add_input('ArmBoolSocket', 'Show Add', default_value=True)
        self.add_input('ArmStringSocket', 'Add Label', default_value='Add')
        self.add_input('ArmBoolSocket', 'Show Remove', default_value=True)

        self.add_output('ArmNodeSocketAction', 'Changed')
        self.add_output('ArmNodeSocketAction', 'Next')
        self.add_output('ArmNodeSocketArray', 'Items')
        self.add_output('ArmIntSocket', 'Position')
