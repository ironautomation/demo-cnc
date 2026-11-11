ACTION act_WorkOffset:
	(* Work offsets G54..G57 (HMI work offset card) : machine position of the program origin per offset. Apply (HMI) takes the
	   table and the active offset over while the CNC is idle (refused otherwise : Output.Rejected). act_Start /
	   act_MoveBlock set the active offset as the standard frame SCS1 (MC_BR_SetStandardFrame, translation only) right before
	   the run, so program and MDI coordinates are relative to that origin : machine = program + offset.
	   While the active offset and the frame set last are both 0 (the default) nothing is set
	   (program coordinates = machine coordinates). Single-axis moves (jog, ManualMove, teach positions), homing, the ring
	   buffer stay in machine coordinates.
	   In-program G54..G59 select the frame table frame (SCS3) of mapp Motion, which is not configured - not used here *)

	(* Apply : only while idle and with sane values - a run in progress keeps its frame *)
	IF gWorkOffset.Input.Command.Apply THEN
		gWorkOffset.Input.Command.Apply := FALSE;
		woOk := cncCommand = E_ACT_IDLE AND NOT programAlive AND woStep = 0
			AND gWorkOffset.Input.Parameter.Active <= 3;
		FOR woIdx := 0 TO 3 DO
			woOk := woOk AND ABS(gWorkOffset.Input.Parameter.Offset[woIdx].X) <= C_WO_MAX
				AND ABS(gWorkOffset.Input.Parameter.Offset[woIdx].Y) <= C_WO_MAX
				AND ABS(gWorkOffset.Input.Parameter.Offset[woIdx].Z) <= C_WO_MAX;
		END_FOR
		IF woOk THEN
			FOR woIdx := 0 TO 3 DO
				gWorkOffset.Output.Offset[woIdx] := gWorkOffset.Input.Parameter.Offset[woIdx];
			END_FOR
			gWorkOffset.Output.Active := gWorkOffset.Input.Parameter.Active;
		END_IF
		gWorkOffset.Output.Rejected := NOT woOk;
	END_IF

	(* frame of the active offset (translation only) *)
	IF gWorkOffset.Output.Active <= 3 THEN
		woIdx := gWorkOffset.Output.Active;
	ELSE
		woIdx := 0;
	END_IF
	woWant.Pos.X := gWorkOffset.Output.Offset[woIdx].X;
	woWant.Pos.Y := gWorkOffset.Output.Offset[woIdx].Y;
	woWant.Pos.Z := gWorkOffset.Output.Offset[woIdx].Z;

	(* set before a run only when an offset is or was in use - it is set again before every run, so a frame that mapp
	   Motion resets at the end of a program (modal data) is back for the next one *)
	woNeed := woWant.Pos.X <> 0.0 OR woWant.Pos.Y <> 0.0 OR woWant.Pos.Z <> 0.0
		OR woSet.Pos.X <> 0.0 OR woSet.Pos.Y <> 0.0 OR woSet.Pos.Z <> 0.0;
	gWorkOffset.Output.InUse := woNeed;

	(* the run that requested the frame is over (also STOP / ABORT while it was set) *)
	IF (woStep = 100 OR woStep = 200) AND cncCommand = E_ACT_IDLE THEN
		woStep := 0;
	END_IF

	CASE woStep OF
		1: (* requested by act_Start / act_MoveBlock *)
			woTimer(IN := FALSE);
			gWorkOffset.Output.Error := FALSE;
			gWorkOffset.Output.ErrorID := 0;
			fbWorkFrame.Frame := woWant;
			fbWorkFrame.Execute := TRUE;
			woStep := 10;

		10:
			woTimer(IN := TRUE, PT := T#2s);

			IF fbWorkFrame.Done THEN
				woTimer(IN := FALSE);
				fbWorkFrame.Execute := FALSE;
				woSet := fbWorkFrame.Frame;
				woStep := 100;
			ELSIF fbWorkFrame.Error OR woTimer.Q THEN
				(* the run is not started : it would run at the wrong place *)
				woTimer(IN := FALSE);
				fbWorkFrame.Execute := FALSE;
				gWorkOffset.Output.Error := TRUE;
				gWorkOffset.Output.ErrorID := fbWorkFrame.ErrorID;
				woStep := 200;
			END_IF

		100:
			;(* set - the action goes on with the run *)

		200:
			;(* failed - the action ends with 200 *)
	END_CASE

END_ACTION
