
(* selected axis (selectAxis 1..3 = X..Z) : stop the other axes, take the actual position as the start of the target once *)
ACTION act_SelectAxis:

	ax := selectAxis - 1;

	FOR i := 0 TO AX_LAST DO
		IF i <> ax AND NOT fbMpgStatus[i].StandStill THEN
			fbMpgStop[i].Execute := TRUE;
			axisActive[i] := FALSE;
		END_IF
	END_FOR

	IF NOT axisActive[ax] THEN
		axisActive[ax] := TRUE;
		target := fbMpgPosition[ax].Position;
	END_IF

	fbMpgMove[ax].Velocity := gAxis[ax].Input.Parameter.JogSpeed; (* [mm/s] *)

END_ACTION

(* step per detent from the x1 / x10 / x100 selector *)
ACTION act_SelectStep:

	IF DI_MPG_X1 THEN
		stepPerDetent := STEP_X1;
	ELSIF DI_MPG_X10 THEN
		stepPerDetent := STEP_X10;
	ELSIF DI_MPG_X100 THEN
		stepPerDetent := STEP_X100;
	END_IF

END_ACTION

(* counter change -> new target of the active axis, kept inside the software limits.
   The first change after a reset only synchronises the counter *)
ACTION act_CountPulses:

	delta := counterValue - prevCounter;

	IF delta <> 0 THEN

		IF NOT counterSynced THEN
			counterSynced := TRUE;
			prevCounter := counterValue;
			RETURN;
		END_IF

		FOR i := 0 TO AX_LAST DO
			IF axisActive[i] THEN
				target := target + DINT_TO_LREAL(delta) * stepPerDetent / COUNTS_PER_DETENT;
				IF delta > 0 THEN
					target := MIN(target, DINT_TO_LREAL(gAxis[i].Input.Parameter.SoftwareLimitsPos));
				ELSE
					target := MAX(target, DINT_TO_LREAL(gAxis[i].Input.Parameter.SoftwareLimitsNeg));
				END_IF
				fbMpgMove[i].Position := target;
				fbMpgMove[i].Execute := FALSE; (* drop -> re-armed next scan *)
				movePending[i] := TRUE;
			END_IF
		END_FOR

	END_IF

	prevCounter := counterValue;

END_ACTION
