
PROGRAM _CYCLIC
	
	(* mode selector switch not wired : HMI selects the mode. A change is taken over only while the CNC is idle *)
	IF gEquipment.Output.Status.CurrentAction = E_ACT_IDLE AND NOT gEquipment.Output.Status.ProgramActive AND NOT gEquipment.Output.State.Move THEN
		DI_Auto := NOT gEquipment.Input.Command.ManualMode;
	END_IF

	Action_ControlButton;

	(* MPG has no enable switch : an axis selected on the MPG means MPG mode (blocks AxisManual) *)
	DI_MPG_Jog_Enable := DI_MPG_AxisX OR DI_MPG_AxisY OR DI_MPG_AxisZ;
	
END_PROGRAM
