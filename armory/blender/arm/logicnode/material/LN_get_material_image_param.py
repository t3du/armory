from arm.logicnode.arm_nodes import *

class GetMaterialImageParamNode(ArmLogicTreeNode):
    """Set an image value material parameter to the specified object. 
    
    @seeNode Get Scene Root
    
    @input Object: Object whose material parameter should change. Use `Get Scene Root` node to set parameter globally.
    
    @input Per Object: 
        - `Enabled`: Set material parameter specific to this object. Global parameter will be ignored.
        - `Disabled`: Set parameter globally, including this object.

    @input Material: Material whose parameter to be set.

    @input Node: Name of the parameter.

    @output Image: Name of the image.
    """
    bl_idname = 'LNGetMaterialImageParamNode'
    bl_label = 'Get Material Image Param'
    arm_section = 'params'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketObject', 'Object')
        self.add_input('ArmBoolSocket', 'Per Object')
        self.add_input('ArmDynamicSocket', 'Material')
        self.add_input('ArmStringSocket', 'Node')

        self.add_output('ArmStringSocket', 'Image')