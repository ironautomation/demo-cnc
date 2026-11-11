ACTION act_MoveResult:

	(* result of the position move (Input.Command.ManualMove) for the HMI : gManualMoveResult - reporting only, the move
	   (Cyclic acceptance, act_MovePosition) is not changed. Called right after act_MovePosition, so the checks below see the values it saw.
	   A refused request and a cancelled move are reported as such, not as arrived *)

	(* why act_MovePosition ends a running move in this scan - its two checks, MOVE_RSN_NONE = it does not *)
	IF gEquipment.Output.Status.EmergencyStop THEN
		moveEndReason := MOVE_RSN_ESTOP;
	ELSIF DI_Auto THEN
		moveEndReason := MOVE_RSN_AUTO;
	ELSIF DI_MPG_Jog_Enable THEN
		moveEndReason := MOVE_RSN_HANDWHEEL;
	ELSIF gEquipment.Output.Status.CurrentAction <> E_ACT_IDLE THEN
		moveEndReason := MOVE_RSN_CNC_BUSY;
	ELSIF gAxis[AX_X].Output.State.Error OR gAxis[AX_Y].Output.State.Error OR gAxis[AX_Z].Output.State.Error THEN
		moveEndReason := MOVE_RSN_AXIS_ERROR;
	ELSIF NOT fbAxisInfo[AX_X].PowerOn OR NOT fbAxisInfo[AX_Y].PowerOn OR NOT fbAxisInfo[AX_Z].PowerOn THEN
		moveEndReason := MOVE_RSN_SERVO_OFF;
	ELSIF NOT allHomed THEN
		moveEndReason := MOVE_RSN_NOT_HOMED;
	ELSE
		moveEndReason := MOVE_RSN_NONE;
	END_IF

	IF moveReq THEN
		(* a request was taken in this scan : Result / Reason now belong to request number Count *)
		gManualMoveResult.Count := gManualMoveResult.Count + 1;
		gManualMoveResult.Reason := MOVE_RSN_NONE;
		moveFailed := FALSE;

		IF NOT moveAccepted THEN
			(* dropped by the acceptance in Cyclic - its conditions in this order *)
			gManualMoveResult.Result := MOVE_RES_REFUSED;
			IF gEquipment.Output.Status.EmergencyStop THEN
				gManualMoveResult.Reason := MOVE_RSN_ESTOP;
			ELSIF DI_Auto THEN
				gManualMoveResult.Reason := MOVE_RSN_AUTO;
			ELSIF DI_MPG_Jog_Enable THEN
				gManualMoveResult.Reason := MOVE_RSN_HANDWHEEL;
			ELSIF gEquipment.Input.CncCommand <> E_ACT_IDLE THEN
				gManualMoveResult.Reason := MOVE_RSN_CNC_BUSY;
			ELSIF gEquipment.Output.State.Move THEN
				gManualMoveResult.Reason := MOVE_RSN_MOVING;
			ELSE
				gManualMoveResult.Reason := MOVE_RSN_NOT_HOMED; (* the only other case Cyclic drops it *)
			END_IF
		ELSIF moveStep >= 100 THEN
			(* accepted, but act_MovePosition ended it in the same scan (servo off, axis error, CNC command) : nothing moved *)
			gManualMoveResult.Result := MOVE_RES_REFUSED;
			gManualMoveResult.Reason := moveEndReason;
		ELSE
			gManualMoveResult.Result := MOVE_RES_RUNNING;
		END_IF

	ELSIF gManualMoveResult.Result = MOVE_RES_RUNNING THEN
		(* an absolute move of the sequence ended aborted or with an error : the sequence goes on, the target may not be reached.
		   The FB outputs are still set here - the axis step 1 in Cyclic releases them later in this scan *)
		FOR i := 0 TO AX_LAST BY 1 DO
			IF fbMoveAbs[i].CommandAborted OR fbMoveAbs[i].Error THEN
				moveFailed := TRUE;
			END_IF
		END_FOR

		IF moveStepIn >= 100 THEN
			(* ended between two scans : only the axis HALT / STOP check in Cyclic does that *)
			gManualMoveResult.Result := MOVE_RES_CANCELLED;
			gManualMoveResult.Reason := MOVE_RSN_AXIS_HALT;
		ELSIF moveStep >= 100 THEN
			IF moveEndReason <> MOVE_RSN_NONE THEN
				gManualMoveResult.Result := MOVE_RES_CANCELLED;
				gManualMoveResult.Reason := moveEndReason;
			ELSIF moveFailed THEN
				gManualMoveResult.Result := MOVE_RES_CANCELLED;
				gManualMoveResult.Reason := MOVE_RSN_STEP_FAILED;
			ELSE
				gManualMoveResult.Result := MOVE_RES_ARRIVED; (* step 60 : every step of the sequence done *)
			END_IF
		END_IF
	END_IF

END_ACTION
