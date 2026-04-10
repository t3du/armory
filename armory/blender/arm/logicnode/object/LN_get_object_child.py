from arm.logicnode.arm_nodes import *

class GetChildNode(ArmLogicTreeNode):
    """Returns the child of the given object by name or by a specific type."""
    bl_idname = 'LNGetChildNode'
    bl_label = 'Get Object Child'
    arm_section = 'relations'
    arm_version = 1

    def sw_update(self, context):
        self.inputs[1].hide = (self.property0 == 'By Type')

    property0: HaxeEnumProperty(
        'property0',
        items = [('By Name', 'By Name', 'By Name'),
                 ('Contains', 'Contains', 'Contains'),
                 ('Starts With', 'Starts With', 'Starts With'),
                 ('Ends With', 'Ends With', 'Ends With'),
                 ('By Type', 'By Type', 'By Type')],
        name='Method', default='By Name', update=sw_update)

    property1: HaxeEnumProperty(
        'property1',
        items = [('MeshObject', 'Mesh', 'MeshObject'),
                 ('CameraObject', 'Camera', 'CameraObject'),
                 ('LightObject', 'Light', 'LightObject'),
                 ('SpeakerObject', 'Speaker', 'SpeakerObject'),
                 ('DecalObject', 'Decal', 'DecalObject'),
                 ('ProbeObject', 'Probe', 'ProbeObject')],
        name='Type', default='MeshObject')

    def arm_init(self, context):
        self.add_input('ArmNodeSocketObject', 'Parent')
        self.add_input('ArmStringSocket', 'Child Name')
        self.add_output('ArmNodeSocketObject', 'Child')

    def draw_buttons(self, context, layout):
        layout.prop(self, 'property0')

        if self.property0 == 'By Type':
            layout.prop(self, 'property1')