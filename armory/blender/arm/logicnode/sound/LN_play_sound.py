import bpy

from arm.logicnode.arm_nodes import *


class PlaySoundNode(ArmLogicTreeNode):
    """Plays the given sound.

    @input Play: Plays the sound, or if paused, resumes the playback.
        The exact behaviour depends on the Retrigger option (see below).
    @input Pause: Pauses the playing sound. If no sound is playing,
        nothing happens.
    @input Stop: Stops the playing sound. If the playback is paused,
        this will reset the playback position to the start of the sound.
    @input Set Volume: Updates the volume of the current playback.
    @input Volume: Volume of the playback. Typically ranges from 0 to 1.

    @output Out: activated once when Play is activated.
    @output Running: activated while the playback is active.
    @output Done: activated when the playback has finished or was
        stopped manually.

    @option Sound/Sound Name: specify a sound by a resource or a string name
    @option Sound: The sound that will be played.
    @option Stream: Stream the sound from disk.
    @option Loop: Whether to loop the playback.
    @option Retrigger: If true, the playback position will be reset to
        the beginning on each activation of Play. If false, the playback
        will continue at the current position.
    @option Pitch: this controls the pitch and the playback speed.
    """
    bl_idname = 'LNPlaySoundRawNode'
    bl_label = 'Play Sound'
    bl_width_default = 200
    arm_section = 'raw'
    arm_version = 5

    def remove_extra_inputs(self, context):
        while len(self.inputs) > 6:
            self.inputs.remove(self.inputs[-1])
        if self.property4 == 'Sound Name':
            self.add_input('ArmStringSocket', 'Sound Name')

    property0: HaxePointerProperty('property0', name='', type=bpy.types.Sound)

    property1: HaxeBoolProperty(
        'property1',
        name='Loop',
        description='Play the sound in a loop',
        default=False)
    property2: HaxeBoolProperty(
        'property2',
        name='Retrigger',
        description='Play the sound from the beginning every time',
        default=False)
    property3: HaxeBoolProperty(
        'property3',
        name='Stream',
        description='Stream the sound from disk',
        default=False)
    property4: HaxeEnumProperty(
    'property4',
    items = [('Sound', 'Sound', 'Sound'),
             ('Sound Name', 'Sound Name', 'Sound Name')],
    name='', default='Sound', update=remove_extra_inputs)

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'Play')
        self.add_input('ArmNodeSocketAction', 'Pause')
        self.add_input('ArmNodeSocketAction', 'Stop')
        self.add_input('ArmNodeSocketAction', 'Set Volume')
        self.add_input('ArmFloatSocket', 'Volume', default_value=1.0)
        self.add_input('ArmFloatSocket', 'Pitch', default_value=1.0)

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmNodeSocketAction', 'Is Running')
        self.add_output('ArmNodeSocketAction', 'Done')
        self.add_output('ArmFloatSocket', 'Length')
        self.add_output('ArmFloatSocket', 'Position')

    def draw_buttons(self, context, layout):
        layout.prop(self, 'property4')

        col = layout.column(align=True)

        if self.property4 == 'Sound':
            col.prop_search(self, 'property0', bpy.data, 'sounds', icon='NONE', text='')

        col.prop(self, 'property3')
        col.prop(self, 'property1')
        col.prop(self, 'property2')


    def get_replacement_node(self, node_tree: bpy.types.NodeTree):
        return NodeReplacement.Identity(self)