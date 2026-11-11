from arm.logicnode.arm_nodes import *

class TickerNode(ArmLogicTreeNode):
    """Ticker"""
    bl_idname = 'LNTickerNode'
    bl_label = 'Ticker'
    arm_version = 1

    def arm_init(self, context):
        self.add_input('ArmNodeSocketAction', 'Start')
        self.add_input('ArmNodeSocketAction', 'Stop')
        self.add_input('NodeSocketFloat', 'Time')

        self.add_output('ArmNodeSocketAction', 'Tick')
        self.add_output('NodeSocketFloat', 'Time')
        self.add_output('NodeSocketInt', 'Count')