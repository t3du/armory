from arm.logicnode.arm_nodes import *

class DrawObjectDisplayNode(ArmLogicTreeNode):
	"""Draws object display lines: Bounds/Wireframe/Outline.

	@input Start: Activate to start drawing every frame.
	@input Stop: Activate to stop drawing.

	@output Out: Activated after Start or Stop is processed.
	"""
	bl_idname = 'LNDrawObjectDisplayNode'
	bl_label = 'Draw Object Display'
	arm_section = 'draw3d'
	arm_version = 1

	def arm_init(self, context):
		self.add_input('ArmNodeSocketAction', 'Start')
		self.add_input('ArmNodeSocketAction', 'Stop')
		self.add_input('ArmNodeSocketObject', 'Object')
		self.add_input('ArmIntSocket', '0/1/2=Bounds/Wireframe/Outline')
		self.add_input('ArmColorSocket', 'Color', default_value=[1.0, 1.0, 1.0, 1.0])
		self.add_input('ArmFloatSocket', 'Strength', default_value=0.1)

		self.add_output('ArmNodeSocketAction', 'Out')