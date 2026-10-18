from arm.logicnode.arm_nodes import *

class DrawLines3DNode(ArmLogicTreeNode):
	"""Draws a list of 3D lines.

	@input Start: Activate to start drawing every frame.
	@input Stop: Activate to stop drawing.
	@input Array (start, end, color, strength): Array of arrays. Each element is [start (Vec4), end (Vec4), color (Vec4 rgba 0-1), strength (Float)].

	@output Out: Activated after Start or Stop is processed.
	"""
	bl_idname = 'LNDrawLines3DNode'
	bl_label = 'Draw Lines 3D'
	arm_section = 'draw3d'
	arm_version = 1

	def arm_init(self, context):
		self.add_input('ArmNodeSocketAction', 'Start')
		self.add_input('ArmNodeSocketAction', 'Stop')
		self.add_input('ArmNodeSocketArray', 'Array (Start, End, Color, Strength)')

		self.add_output('ArmNodeSocketAction', 'Out')