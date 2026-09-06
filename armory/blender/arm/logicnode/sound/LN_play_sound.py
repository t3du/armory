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
        if self.arm_version == 4:

            # v4:
            # property3 = Use Custom Sample Rate
            # property4 = Sample Rate
            # property5 = Stream
            # property6 = Sound / Sound Name
            #
            # v5:
            # property3 = Stream
            # property4 = Sound / Sound Name
            # input 5   = Pitch

            # Read old v4 properties directly from Blender ID properties.
            old_stream = self.get('property5', False)
            old_sound_mode = self.get('property6', 0)

            # property6 was stored as an integer enum in old nodes.
            # Convert it to the string identifier expected by the new
            # EnumProperty.
            #
            # 0 = Sound
            # 1 = Sound Name
            if isinstance(old_sound_mode, int):
                old_sound_mode = 'Sound Name' if old_sound_mode == 1 else 'Sound'

            # Be defensive in case an unexpected old value exists.
            if old_sound_mode not in {'Sound', 'Sound Name'}:
                old_sound_mode = 'Sound'

            input_mapping = {
                0: 0,  # Play
                1: 1,  # Pause
                2: 2,  # Stop
                3: 3,  # Set Volume
                4: 4,  # Volume
            }

            # In v4 Sound Name was input 5.
            # In v5 Pitch occupies input 5, so Sound Name becomes input 6.
            if old_sound_mode == 'Sound Name' and len(self.inputs) > 5:
                input_mapping[5] = 6

            return NodeReplacement(
                'LNPlaySoundRawNode',
                4,
                'LNPlaySoundRawNode',
                5,

                # Input socket mapping
                input_mapping,

                # Output socket mapping
                {
                    0: 0,
                    1: 1,
                    2: 2,
                    3: 3,
                    4: 4,
                },

                # Properties whose meaning remains unchanged
                {
                    'property0': 'property0',
                    'property1': 'property1',
                    'property2': 'property2',
                },

                # Defaults for newly added inputs
                {
                    5: 1.0,  # Pitch
                },

                # New v5 property values
                {
                    'property3': old_stream,
                    'property4': old_sound_mode,
                }
            )

        return NodeReplacement.Identity(self)



