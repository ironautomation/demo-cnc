ACTION act_ZRefCheck:
	(* gZRef.Input valid for a measurement (machine coordinates, Z+ down, 0 = top) : SafeZ <= StartZ < MaxZ, search at most
	   C_ZREF_MAX_SEARCH, everything inside the software limits of gAxis[].Input.Parameter (loaded from the axis configuration
	   by AxisManual), search velocity at most C_ZREF_MAX_VEL. The defaults (all 0) are not valid : nothing moves until the HMI
	   has written the sensor position *)
	zrVel := gZRef.Input.ProbeVel;
	IF zrVel <= 0.0 THEN
		zrVel := C_ZREF_PROBE_VEL;
	END_IF

	gZRef.Output.ParamOk := gZRef.Input.MaxZ > gZRef.Input.StartZ
		AND gZRef.Input.MaxZ - gZRef.Input.StartZ <= C_ZREF_MAX_SEARCH
		AND gZRef.Input.SafeZ <= gZRef.Input.StartZ
		AND zrVel <= C_ZREF_MAX_VEL
		AND gZRef.Input.SafeZ >= DINT_TO_LREAL(gAxis[AX_Z].Input.Parameter.SoftwareLimitsNeg)
		AND gZRef.Input.MaxZ <= DINT_TO_LREAL(gAxis[AX_Z].Input.Parameter.SoftwareLimitsPos)
		AND gZRef.Input.SensorX >= DINT_TO_LREAL(gAxis[AX_X].Input.Parameter.SoftwareLimitsNeg)
		AND gZRef.Input.SensorX <= DINT_TO_LREAL(gAxis[AX_X].Input.Parameter.SoftwareLimitsPos)
		AND gZRef.Input.SensorY >= DINT_TO_LREAL(gAxis[AX_Y].Input.Parameter.SoftwareLimitsNeg)
		AND gZRef.Input.SensorY <= DINT_TO_LREAL(gAxis[AX_Y].Input.Parameter.SoftwareLimitsPos);

END_ACTION

ACTION act_MeasureZ:
	(* Z reference measurement (CncCommand E_ACT_MEASURE_Z) : Z up to SafeZ, X / Y to the sensor, Z to StartZ, then Z slowly
	   down towards MaxZ until the touch sensor DI_ZRef_Sensor comes on : that Z is the result (gZRef.Output.MeasuredZ, the
	   HMI puts it into the head table), Z brakes and goes back up to SafeZ. Single-axis moves in machine coordinates with
	   own FBs (fbZrMove / fbZrHalt), like AxisManual's ManualMove; the CNC program path is not used, so work / head offsets
	   do not shift it. Accepted only in manual mode, homed, standing (preconditions in Cyclic).
	   DI_ZRef_Sensor is NOT wired yet : without a sensor the search reaches MaxZ and ends with ErrorId 3 *)

	CASE commandStep OF
		0: (* take the input over, clear the last result *)
			stepTimer(IN := FALSE);
			act_ZRefCheck;
			gZRef.Output.Done := FALSE;
			gZRef.Output.ErrorId := 0;
			zrFail := 0;
			FOR i := 0 TO 2 DO
				fbZrMove[i].Execute := FALSE;
				fbZrHalt[i].Execute := FALSE;
			END_FOR
			zrMoveVel := gEquipment.Input.Parameter.SystemSpeed; (* like ManualMove *)
			IF zrMoveVel <= 0.0 THEN
				zrMoveVel := C_ZREF_MOVE_VEL;
			END_IF

			IF gZRef.Output.ParamOk THEN
				zrActive := TRUE;
				commandStep := 10;
			ELSE
				gZRef.Output.ErrorId := 1;
				commandStep := 200;
			END_IF

		10: (* Z up to SafeZ first - a head already above SafeZ stays there (Z never goes down before X / Y move) *)
			fbZrMove[2].Position := MIN(gZRef.Input.SafeZ, gAxis[AX_Z].Output.State.Position);
			fbZrMove[2].Velocity := zrMoveVel;
			fbZrMove[2].Execute := TRUE;
			stepTimer(IN := FALSE);
			commandStep := 11;

		11:
			stepTimer(IN := TRUE, PT := T#60s);

			IF fbZrMove[2].Done THEN
				stepTimer(IN := FALSE);
				fbZrMove[2].Execute := FALSE;
				commandStep := 20;
			ELSIF fbZrMove[2].Error OR fbZrMove[2].CommandAborted THEN
				zrFail := 4;
				commandStep := 190;
			ELSIF stepTimer.Q THEN
				zrFail := 6;
				commandStep := 190;
			END_IF

		20: (* X / Y over the sensor *)
			fbZrMove[0].Position := gZRef.Input.SensorX;
			fbZrMove[0].Velocity := zrMoveVel;
			fbZrMove[0].Execute := TRUE;
			fbZrMove[1].Position := gZRef.Input.SensorY;
			fbZrMove[1].Velocity := zrMoveVel;
			fbZrMove[1].Execute := TRUE;
			stepTimer(IN := FALSE);
			commandStep := 21;

		21:
			stepTimer(IN := TRUE, PT := T#60s);

			IF fbZrMove[0].Done AND fbZrMove[1].Done THEN
				stepTimer(IN := FALSE);
				fbZrMove[0].Execute := FALSE;
				fbZrMove[1].Execute := FALSE;
				commandStep := 30;
			ELSIF fbZrMove[0].Error OR fbZrMove[0].CommandAborted OR fbZrMove[1].Error OR fbZrMove[1].CommandAborted THEN
				zrFail := 4;
				commandStep := 190;
			ELSIF stepTimer.Q THEN
				zrFail := 6;
				commandStep := 190;
			END_IF

		30: (* Z down to StartZ *)
			fbZrMove[2].Position := gZRef.Input.StartZ;
			fbZrMove[2].Velocity := zrMoveVel;
			fbZrMove[2].Execute := TRUE;
			stepTimer(IN := FALSE);
			commandStep := 31;

		31:
			stepTimer(IN := TRUE, PT := T#60s);

			IF fbZrMove[2].Done THEN
				stepTimer(IN := FALSE);
				fbZrMove[2].Execute := FALSE;
				commandStep := 40;
			ELSIF fbZrMove[2].Error OR fbZrMove[2].CommandAborted THEN
				zrFail := 4;
				commandStep := 190;
			ELSIF stepTimer.Q THEN
				zrFail := 6;
				commandStep := 190;
			END_IF

		40: (* slow search towards MaxZ - the sensor must be off here (else StartZ is too low or the sensor is stuck) *)
			IF DI_ZRef_Sensor THEN
				zrFail := 2;
				commandStep := 60;
			ELSE
				fbZrMove[2].Position := gZRef.Input.MaxZ;
				fbZrMove[2].Velocity := zrVel;
				fbZrMove[2].Execute := TRUE;
				stepTimer(IN := FALSE);
				commandStep := 41;
			END_IF

		41:
			stepTimer(IN := TRUE, PT := T#60s);

			IF DI_ZRef_Sensor THEN
				(* Z of the last cycle (AxisManual runs after Main) : error up to about zrVel x 2 cycles + the input filter *)
				gZRef.Output.MeasuredZ := gAxis[AX_Z].Output.State.Position;
				stepTimer(IN := FALSE);
				fbZrMove[2].Execute := FALSE;
				fbZrHalt[2].Execute := TRUE;
				commandStep := 50;
			ELSIF fbZrMove[2].Done THEN
				(* MaxZ reached without a signal (no sensor, sensor not wired) *)
				stepTimer(IN := FALSE);
				fbZrMove[2].Execute := FALSE;
				zrFail := 3;
				commandStep := 60;
			ELSIF fbZrMove[2].Error OR fbZrMove[2].CommandAborted THEN
				zrFail := 4;
				commandStep := 190;
			ELSIF stepTimer.Q THEN
				zrFail := 6;
				commandStep := 190;
			END_IF

		50: (* braking on the sensor *)
			stepTimer(IN := TRUE, PT := T#5s);

			IF fbZrHalt[2].Done THEN
				stepTimer(IN := FALSE);
				fbZrHalt[2].Execute := FALSE;
				commandStep := 60;
			ELSIF fbZrHalt[2].Error OR fbZrHalt[2].CommandAborted THEN
				zrFail := 4;
				commandStep := 190;
			ELSIF stepTimer.Q THEN
				zrFail := 6;
				commandStep := 190;
			END_IF

		60: (* Z back up to SafeZ - also after ErrorId 2 / 3 *)
			fbZrMove[2].Position := gZRef.Input.SafeZ;
			fbZrMove[2].Velocity := zrMoveVel;
			fbZrMove[2].Execute := TRUE;
			stepTimer(IN := FALSE);
			commandStep := 61;

		61:
			stepTimer(IN := TRUE, PT := T#60s);

			IF fbZrMove[2].Done THEN
				stepTimer(IN := FALSE);
				fbZrMove[2].Execute := FALSE;
				zrActive := FALSE;
				IF zrFail = 0 THEN
					gZRef.Output.Head := gZRef.Input.Head;
					gZRef.Output.Done := TRUE;
					commandStep := 100;
				ELSE
					gZRef.Output.ErrorId := zrFail;
					commandStep := 200;
				END_IF
			ELSIF fbZrMove[2].Error OR fbZrMove[2].CommandAborted THEN
				zrFail := 4;
				commandStep := 190;
			ELSIF stepTimer.Q THEN
				zrFail := 6;
				commandStep := 190;
			END_IF

		190: (* a move failed : brake what this cycle still moves, no result *)
			stepTimer(IN := FALSE);
			FOR i := 0 TO 2 DO
				IF fbZrMove[i].Busy THEN
					fbZrHalt[i].Execute := TRUE;
				END_IF
				fbZrMove[i].Execute := FALSE;
			END_FOR
			gZRef.Output.ErrorId := zrFail;
			zrActive := FALSE;
			commandStep := 200;

		100:
			zrActive := FALSE;(* Complete - gZRef.Output.MeasuredZ / Head *)

		200:
			zrActive := FALSE;(* failed - gZRef.Output.ErrorId *)
	END_CASE

END_ACTION

ACTION act_ZRef:
	(* every cycle : input check for the next command, end of a measurement that was left (STOP, ABORT, E-stop, handwheel),
	   release of the halts, status *)
	act_ZRefCheck;

	IF zrActive AND (cncCommand <> E_ACT_MEASURE_Z OR DI_MPG_Jog_Enable OR emergencyLatched) THEN
		(* brake what the measurement still moves, the result is not valid *)
		FOR i := 0 TO 2 DO
			IF fbZrMove[i].Busy THEN
				fbZrHalt[i].Execute := TRUE;
			END_IF
			fbZrMove[i].Execute := FALSE;
		END_FOR
		gZRef.Output.ErrorId := 5;
		zrActive := FALSE;
		IF cncCommand = E_ACT_MEASURE_Z THEN
			commandStep := 200; (* handwheel : the command ends *)
		END_IF
	END_IF

	IF NOT zrActive THEN
		FOR i := 0 TO 2 DO
			IF fbZrHalt[i].Done OR fbZrHalt[i].Error OR fbZrHalt[i].CommandAborted THEN
				fbZrHalt[i].Execute := FALSE;
			END_IF
		END_FOR
	END_IF

	gZRef.Output.Sensor := DI_ZRef_Sensor;
	gZRef.Output.Busy := zrActive;
	IF zrActive THEN
		gZRef.Output.Step := commandStep;
	ELSE
		gZRef.Output.Step := 0;
	END_IF

END_ACTION
