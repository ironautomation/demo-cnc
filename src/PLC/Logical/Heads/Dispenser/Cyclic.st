
PROGRAM _CYCLIC

	(* mode change (auto <-> manual) : discharge off, both commands dropped *)
	toAuto(CLK := gEquipment.Output.Status.Mode);
	toManual(CLK := gEquipment.Output.Status.Mode);
	IF toAuto.Q OR toManual.Q THEN
		gDispenser.Input.Command.Discharge := FALSE;
		gDispenser.Input.Command.Manual := FALSE;
		DO_Dispenser_Start := FALSE;
	END_IF

	(* auto : M41 / M42 (Command.Discharge, driven by Main), manual : Command.Manual from the HMI *)
	IF gEquipment.Output.Status.Mode THEN
		command := gDispenser.Input.Command.Discharge;
	ELSE
		command := gDispenser.Input.Command.Manual;
	END_IF

	(* on with the rising edge (not in dry run), off with the falling edge *)
	commandOn(CLK := command);
	commandOff(CLK := command);

	IF commandOn.Q AND NOT gEquipment.Input.Parameter.DryRun THEN
		DO_Dispenser_Start := TRUE;
	ELSIF commandOff.Q THEN
		DO_Dispenser_Start := FALSE;
	END_IF

	gDispenser.Output.State.Discharge := DO_Dispenser_Start;

END_PROGRAM
