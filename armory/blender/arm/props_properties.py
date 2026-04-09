import bpy
from bpy.types import Menu, Panel, UIList
from bpy.props import *

class ArmArrayItem(bpy.types.PropertyGroup):
    name_prop: StringProperty(name="Name", default="Item")
    index_prop: IntProperty(name="Index", default=0, options={'HIDDEN', 'SKIP_SAVE'})
    string_prop: StringProperty(name="String", default="")
    integer_prop: IntProperty(name="Integer", default=0)
    float_prop: FloatProperty(name="Float", default=0.0)
    boolean_prop: BoolProperty(name="Boolean", default=False)
    vector_prop: FloatVectorProperty(name="Vector", default=(0.0, 0.0, 0.0), size=3)

class ArmPropertyListItem(bpy.types.PropertyGroup):
    type_prop: EnumProperty(
        items = [('string', 'String', 'String'),
                 ('integer', 'Integer', 'Integer'),
                 ('float', 'Float', 'Float'),
                 ('boolean', 'Boolean', 'Boolean'),
                 ('vector', 'Vector', 'Vector'),
                 ('array', 'Array', 'Array')],
        name = "Type")
    name_prop: StringProperty(name="Name", default="my_prop")
    string_prop: StringProperty(name="String", default="")
    integer_prop: IntProperty(name="Integer", default=0)
    float_prop: FloatProperty(name="Float", default=0.0)
    boolean_prop: BoolProperty(name="Boolean", default=False)
    vector_prop: FloatVectorProperty(name="Vector", default=(0.0, 0.0, 0.0), size=3)
    array_prop: CollectionProperty(type=ArmArrayItem)
    array_item_type: EnumProperty(
        items = [('string', 'String', 'String'),
                 ('integer', 'Integer', 'Integer'),
                 ('float', 'Float', 'Float'),
                 ('boolean', 'Boolean', 'Boolean'),
                 ('vector', 'Vector', 'Vector')],
        name = "New Item Type", default = 'string')
    array_index: IntProperty(name="Array Index", default=0)

class ARM_UL_ArrayItemList(bpy.types.UIList):
    def draw_item(self, context, layout, data, item, icon, active_data, active_propname, index):
        array_type = data.array_item_type
        if self.layout_type in {'DEFAULT', 'COMPACT'}:
            layout.label(text=str(index))
            if array_type == 'string':
                layout.prop(item, "string_prop", text="")
            elif array_type == 'integer':
                layout.prop(item, "integer_prop", text="")
            elif array_type == 'float':
                layout.prop(item, "float_prop", text="")
            elif array_type == 'boolean':
                layout.prop(item, "boolean_prop", text="")
            elif array_type == 'vector':
                col = layout.column()
                col.prop(item, "vector_prop", text="")

class ARM_UL_PropertyList(bpy.types.UIList):
    def draw_item(self, context, layout, data, item, icon, active_data, active_propname, index):
        layout.use_property_split = False
        if self.layout_type in {'DEFAULT', 'COMPACT'}:
            layout.prop(item, "name_prop", text="", emboss=False, icon="OBJECT_DATAMODE")
            if item.type_prop == 'vector':
                layout.column().prop(item, "vector_prop", text="")
            elif item.type_prop != 'array':
                layout.prop(item, item.type_prop + "_prop", text="", emboss=(item.type_prop == 'boolean'))
            else:
                layout.label(text="[Array]")

def get_arm_target(context):
    try:
        if context.space_data.type == 'PROPERTIES':
            if context.space_data.context == 'SCENE':
                return context.scene
            elif context.space_data.context == 'OBJECT':
                return context.object
    except:
        pass
    return context.object if context.object else context.scene

class ArmArrayAddItem(bpy.types.Operator):
    bl_idname = "arm_array.add_item"
    bl_label = "Add Array Item"
    def execute(self, context):
        target = get_arm_target(context)
        item = target.arm_propertylist[target.arm_propertylist_index]
        item.array_prop.add()
        item.array_index = len(item.array_prop) - 1
        return {'FINISHED'}

class ArmArrayRemoveItem(bpy.types.Operator):
    bl_idname = "arm_array.remove_item"
    bl_label = "Remove Array Item"
    def execute(self, context):
        target = get_arm_target(context)
        item = target.arm_propertylist[target.arm_propertylist_index]
        item.array_prop.remove(item.array_index)
        item.array_index = max(0, item.array_index - 1)
        return {'FINISHED'}

class ArmPropertyListNewItem(bpy.types.Operator):
    bl_idname = "arm_propertylist.new_item"
    bl_label = "New"
    type_prop: EnumProperty(
        items = [('string', 'String', 'String'), ('integer', 'Integer', 'Integer'),
                 ('float', 'Float', 'Float'), ('boolean', 'Boolean', 'Boolean'),
                 ('vector', 'Vector', 'Vector'), ('array', 'Array', 'Array')], name = "Type")
    def invoke(self, context, event):
        return context.window_manager.invoke_props_dialog(self)
    def draw(self, context):
        self.layout.prop(self, "type_prop", expand=True)
    def execute(self, context):
        target = get_arm_target(context)
        prop = target.arm_propertylist.add()
        prop.type_prop = self.type_prop
        target.arm_propertylist_index = len(target.arm_propertylist) - 1
        return {'FINISHED'}

class ArmPropertyListDeleteItem(bpy.types.Operator):
    bl_idname = "arm_propertylist.delete_item"
    bl_label = "Delete"
    def execute(self, context):
        target = get_arm_target(context)
        target.arm_propertylist.remove(target.arm_propertylist_index)
        target.arm_propertylist_index = max(0, target.arm_propertylist_index - 1)
        return {'FINISHED'}

class ArmPropertyListMoveItem(bpy.types.Operator):
    bl_idname = "arm_propertylist.move_item"
    bl_label = "Move"
    direction: EnumProperty(items=(('UP', 'Up', ""), ('DOWN', 'Down', "")))
    def execute(self, context):
        target = get_arm_target(context)
        idx = target.arm_propertylist_index
        new_idx = idx - 1 if self.direction == 'UP' else idx + 1
        if 0 <= new_idx < len(target.arm_propertylist):
            target.arm_propertylist.move(idx, new_idx)
            target.arm_propertylist_index = new_idx
        return {'FINISHED'}

def draw_properties(layout, obj):
    layout.use_property_split = False
    main_col = layout.column()
    main_col.label(text="Properties")
    row = main_col.row()
    row.template_list("ARM_UL_PropertyList", "", obj, "arm_propertylist", obj, "arm_propertylist_index", rows=4)
    btn_col = row.column(align=True)
    btn_col.operator("arm_propertylist.new_item", icon='ADD', text="")
    btn_col.operator("arm_propertylist.delete_item", icon='REMOVE', text="")
    if len(obj.arm_propertylist) > 1:
        btn_col.separator()
        btn_col.operator("arm_propertylist.move_item", icon='TRIA_UP', text="").direction = 'UP'
        btn_col.operator("arm_propertylist.move_item", icon='TRIA_DOWN', text="").direction = 'DOWN'
    
    if len(obj.arm_propertylist) > 0 and obj.arm_propertylist_index < len(obj.arm_propertylist):
        item = obj.arm_propertylist[obj.arm_propertylist_index]
        if item.type_prop == 'array':
            main_col.separator()
            main_col.label(text="Array Items")
            main_col.prop(item, "array_item_type", text="Type")
            row_arr = main_col.row()
            row_arr.template_list("ARM_UL_ArrayItemList", "", item, "array_prop", item, "array_index", rows=4)
            btn_arr = row_arr.column(align=True)
            btn_arr.operator("arm_array.add_item", icon='ADD', text="")
            btn_arr.operator("arm_array.remove_item", icon='REMOVE', text="")

class ARM_PT_ObjectPropsPanel(bpy.types.Panel):
    bl_label = "Armory Props"
    bl_space_type = "PROPERTIES"
    bl_region_type = "WINDOW"
    bl_context = "object"
    def draw(self, context):
        draw_properties(self.layout, context.object)

class ARM_PT_ScenePropsPanel(bpy.types.Panel):
    bl_label = "Armory Props"
    bl_space_type = "PROPERTIES"
    bl_region_type = "WINDOW"
    bl_context = "scene"
    def draw(self, context):
        draw_properties(self.layout, context.scene)

__REG_CLASSES = (
    ArmArrayItem, ArmPropertyListItem, ARM_UL_PropertyList, ARM_UL_ArrayItemList,
    ArmPropertyListNewItem, ArmPropertyListDeleteItem, ArmPropertyListMoveItem,
    ArmArrayAddItem, ArmArrayRemoveItem, ARM_PT_ObjectPropsPanel, ARM_PT_ScenePropsPanel,
)

def register():
    for cls in __REG_CLASSES:
        bpy.utils.register_class(cls)
    bpy.types.Object.arm_propertylist = CollectionProperty(type=ArmPropertyListItem)
    bpy.types.Object.arm_propertylist_index = IntProperty(name="Index", default=0)
    bpy.types.Scene.arm_propertylist = CollectionProperty(type=ArmPropertyListItem)
    bpy.types.Scene.arm_propertylist_index = IntProperty(name="Index", default=0)

def unregister():
    for cls in reversed(__REG_CLASSES):
        bpy.utils.unregister_class(cls)
    del bpy.types.Object.arm_propertylist
    del bpy.types.Object.arm_propertylist_index
    del bpy.types.Scene.arm_propertylist
    del bpy.types.Scene.arm_propertylist_index