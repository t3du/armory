from arm.logicnode.arm_nodes import *


class HashNode(ArmLogicTreeNode):
    """Generates a hash from a string.

    @input In: Executes the hash operation.
    @input String: Text to hash.
    @output Out: Activated after hashing.
    @output Hash: Generated hexadecimal hash.
    @output Length: Number of characters in the hash.
    """
    bl_idname = 'LNHashNode'
    bl_label = 'Hash'
    arm_section = 'data'
    arm_version = 1

    def on_property_update(self, context):
        if self.property0.startswith('HMAC_'):
            if len(self.inputs) < 3:
                self.add_input('ArmStringSocket', 'Key')
        else:
            if len(self.inputs) > 2:
                self.inputs.remove(self.inputs[2])

    property0: HaxeEnumProperty(
        'property0',
        name='Algorithm',
        items=[
            ('MD5', 'MD5', '128-bit message digest'),
            ('SHA1', 'SHA-1', '160-bit secure hash algorithm'),
            ('SHA224', 'SHA-224', '224-bit secure hash algorithm'),
            ('SHA256', 'SHA-256', '256-bit secure hash algorithm'),
            ('CRC32', 'CRC32', '32-bit cyclic redundancy check'),
            ('ADLER32', 'Adler32', '32-bit Adler checksum'),
            ('HMAC_MD5', 'HMAC-MD5', 'HMAC using MD5'),
            ('HMAC_SHA1', 'HMAC-SHA1', 'HMAC using SHA-1'),
            ('HMAC_SHA256', 'HMAC-SHA256', 'HMAC using SHA-256'),
        ],
        default='SHA256',
        update=on_property_update
    )

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmStringSocket', 'String')

        self.add_output('ArmNodeSocketAction', 'Out')
        self.add_output('ArmStringSocket', 'Hash')
        self.add_output('ArmIntSocket', 'Length')

    def draw_buttons(self, context, layout):
        layout.prop(self, 'property0')