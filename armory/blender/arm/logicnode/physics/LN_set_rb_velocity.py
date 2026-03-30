from arm.logicnode.arm_nodes import *

class SetVelocityNode(ArmLogicTreeNode):
    """Sets the velocity of the given rigid body."""
    bl_idname = 'LNSetRigidBodyVelocityNode'
    bl_label = 'Set RB Velocity'
    arm_version = 1

    def update_sockets(self, context):
        self.inputs[2].hide = self.property0 == 'Angular'
        self.inputs[3].hide = self.property0 == 'Linear'

    property0: EnumProperty(
        items=[('Both', 'Both', 'Set both velocities'),
               ('Linear', 'Linear', 'Set only linear velocity'),
               ('Angular', 'Angular', 'Set only angular velocity')],
        name='Velocity',
        default='Both',
        update=update_sockets
    )

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'In')
        self.add_input('ArmNodeSocketObject', 'RB')
        self.add_input('ArmVectorSocket', 'Linear')
        self.add_input('ArmVectorSocket', 'Angular')
        self.add_output('ArmNodeSocketAction', 'Out')

    def draw_buttons(self, context, layout):
        layout.prop(self, 'property0')