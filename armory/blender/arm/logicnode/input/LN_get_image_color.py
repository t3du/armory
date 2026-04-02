from arm.logicnode.arm_nodes import *

class GetImageColorNode(ArmLogicTreeNode):
    """Obtiene el color de un píxel. Soporta imágenes estáticas y Render Targets dinámicos."""
    bl_idname = 'LNGetImageColorNode'
    bl_label = 'Get Image Color'
    arm_version = 1

    def remove_extra_inputs(self, context):
        while len(self.inputs) > 0:
            self.inputs.remove(self.inputs[-1])
        
        if self.property0 == 'Image':
            self.add_input('ArmStringSocket', 'Image Name')
        elif self.property0 == 'RenderTarget':
            # Mantenemos el orden exacto de CreateRenderTargetNode
            self.add_input('ArmNodeSocketObject', 'Object')
            self.add_input('ArmDynamicSocket', 'Material')
            self.add_input('ArmStringSocket', 'Link Name')
            
        self.add_input('ArmIntSocket', 'X')
        self.add_input('ArmIntSocket', 'Y')

    property0: HaxeEnumProperty(
        'property0',
        items = [('Image', 'Image', 'Image'),
                 ('RenderTarget', 'Render Target', 'Dynamic Render Target'),
                 ('Render2D', 'Render2D', 'Render2D'),
                 ('Render', 'Render', 'Render'),
                 ('Render&Render2D', 'Render&Render2D', 'Render&Render2D')],
        name='', default='Image', update=remove_extra_inputs)

    def arm_init(self, context):
        self.add_input('ArmStringSocket', 'Image Name')
        self.add_input('ArmIntSocket', 'X')
        self.add_input('ArmIntSocket', 'Y')
        self.add_output('ArmColorSocket', 'Color')

    def draw_buttons(self, context, layout):
        layout.prop(self, 'property0')