from arm.logicnode.arm_nodes import *

class DetectMobileBrowserNode(ArmLogicTreeNode):
	"""Determines the mobile browser or not."""
	bl_idname = 'LNDetectMobileBrowserNode'
	bl_label = 'Detect Mobile Browser'
	arm_section = 'Native'
	arm_version = 1

	def arm_init(self, context):
		self.add_output('ArmBoolSocket', 'Mobile')
