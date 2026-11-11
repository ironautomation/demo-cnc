

ACTION Action_ControlButton:
	
	(* auto -> manual : stop CNC and discharge *)
	ManualModeTrigger(CLK := DI_Auto);
	
	IF ManualModeTrigger.Q THEN
		gDispenser.Input.Command.Discharge := FALSE;
		gEquipment.Input.CncCommand := E_ACT_STOP;
	END_IF
	
END_ACTION
