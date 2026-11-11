
PROGRAM _CYCLIC

	(* handwheel mode starts : every axis takes its reference again *)
	enableRise(CLK := DI_MPG_Jog_Enable);

	IF enableRise.Q THEN
		FOR i := 0 TO AX_LAST DO
			axisActive[i] := FALSE;
		END_FOR
	END_IF

	(* E-stop : stop the handwheel axis, drop the reference so the next use resyncs to the actual position *)
	emgTrig(CLK := gEquipment.Output.Status.EmergencyStop);

	IF emgTrig.Q THEN
		FOR i := 0 TO AX_LAST DO
			axisActive[i] := FALSE;
			movePending[i] := FALSE;
			fbMpgMove[i].Execute := FALSE;
			fbMpgStop[i].Execute := TRUE;
		END_FOR
	END_IF

	IF gEquipment.Input.CncCommand = E_ACT_IDLE AND NOT gEquipment.Output.State.Move AND NOT gEquipment.Output.Status.EmergencyStop THEN

		IF DI_MPG_AxisX THEN
			selectAxis := 1;
		ELSIF DI_MPG_AxisY THEN
			selectAxis := 2;
		ELSIF DI_MPG_AxisZ THEN
			selectAxis := 3;
		END_IF

		IF selectAxis > 0 THEN
			act_SelectAxis;
			act_SelectStep;

			IF counterReset THEN
				(* counter is being reset : resync so the jump to 0 is not counted as movement *)
				prevCounter := counterValue;
				counterSynced := FALSE;
			ELSE
				act_CountPulses;
			END_IF
		END_IF

		(* counter reset : one cycle pulse *)
		IF selectAxis > 0 AND counterReset THEN
			counterReset := FALSE;
		END_IF

		axisChange(CLK := selectAxis <> lastSelectAxis);

		IF axisChange.Q THEN
			lastSelectAxis := selectAxis;
			counterReset := TRUE;

			(* axis changed without passing through OFF : drop the previous axis reference *)
			FOR i := 0 TO AX_LAST DO
				axisActive[i] := FALSE;
				movePending[i] := FALSE;
				fbMpgMove[i].Execute := FALSE;
			END_FOR
			prevCounter := 0;
			counterSynced := FALSE;
		END_IF

		(* axis selector back to OFF : stop, reset the counter *)
		axisReleased(CLK := DI_MPG_AxisX OR DI_MPG_AxisY OR DI_MPG_AxisZ);

		IF axisReleased.Q THEN
			selectAxis := 0;
			counterReset := TRUE;
			prevCounter := 0;
			counterSynced := FALSE;
			FOR i := 0 TO AX_LAST DO
				axisActive[i] := FALSE;
				fbMpgStop[i].Execute := TRUE;
				movePending[i] := FALSE;
				fbMpgMove[i].Execute := FALSE;
			END_FOR
		END_IF

	END_IF

	(* release stop execute after done *)
	FOR i := 0 TO AX_LAST DO
		IF fbMpgStop[i].Execute AND (fbMpgStop[i].Done OR fbMpgStop[i].Error) THEN
			fbMpgStop[i].Execute := FALSE;
		END_IF
	END_FOR

	(* MC_MoveAbsolute retrigger : drop Execute one scan, re-arm with new target *)
	FOR i := 0 TO AX_LAST DO
		IF movePending[i] AND NOT fbMpgMove[i].Execute THEN
			fbMpgMove[i].Execute := TRUE;
			movePending[i] := FALSE;
		END_IF

		IF fbMpgMove[i].Execute AND (fbMpgMove[i].Done OR fbMpgMove[i].Error OR fbMpgMove[i].CommandAborted) THEN
			fbMpgMove[i].Execute := FALSE;
		END_IF

		fbMpgMove[i]();
		fbMpgStop[i]();
		fbMpgPosition[i]();
		fbMpgStatus[i]();
	END_FOR

END_PROGRAM
