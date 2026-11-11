ACTION act_MovePosition:

	(* abort on E-stop, axis error or lost homing - the wait steps below would never finish *)
	IF moveStep < 100 AND (NOT allHomed OR gEquipment.Output.Status.EmergencyStop OR gAxis[AX_X].Output.State.Error OR gAxis[AX_Y].Output.State.Error OR gAxis[AX_Z].Output.State.Error) THEN
		moveStep := 100;
	END_IF

	(* also end it when the machine leaves manual operation or an axis loses power, so it never
	   moves on by itself once the servo is back. A HALT / STOP of an axis ends it in Cyclic *)
	IF moveStep < 100 AND (DI_Auto OR DI_MPG_Jog_Enable OR gEquipment.Output.Status.CurrentAction <> E_ACT_IDLE OR
		NOT fbAxisInfo[AX_X].PowerOn OR NOT fbAxisInfo[AX_Y].PowerOn OR NOT fbAxisInfo[AX_Z].PowerOn) THEN
		moveStep := 100;
	END_IF

	CASE moveStep OF
		0:
			IF gAxis[AX_X].Input.Command.Command = Axis_IDLE AND gAxis[AX_Y].Input.Command.Command = Axis_IDLE AND gAxis[AX_Z].Input.Command.Command = Axis_IDLE THEN
				moveStep := 10;
			END_IF
			
		10: (* retract Z first *)
			gEquipment.Output.Status.ManualMove := TRUE;
			
			gAxis[AX_Z].Input.Parameter.Speed := gEquipment.Input.Parameter.SystemSpeed;
			gAxis[AX_Z].Input.Parameter.Position := 0;
			gAxis[AX_Z].Input.Command.Command := Axis_MOVE_ABSOLUTE;
			moveStep := 20;
			
		20:
			IF gAxis[AX_Z].Output.State.Status = 1 AND command[AX_Z] = Axis_IDLE AND fbAxisStatus[AX_Z].StandStill = TRUE THEN
				moveStep := 30;
			END_IF
			
		30: (* move X / Y *)
			gAxis[AX_X].Input.Parameter.Speed := gEquipment.Input.Parameter.SystemSpeed;
			gAxis[AX_X].Input.Parameter.Position := gEquipment.Input.Parameter.ManualPositon[0];
			gAxis[AX_X].Input.Command.Command := Axis_MOVE_ABSOLUTE;
			gAxis[AX_Y].Input.Parameter.Speed := gEquipment.Input.Parameter.SystemSpeed;
			gAxis[AX_Y].Input.Parameter.Position := gEquipment.Input.Parameter.ManualPositon[1];
			gAxis[AX_Y].Input.Command.Command := Axis_MOVE_ABSOLUTE;
			moveStep := 40;
			
		40:
			IF gAxis[AX_X].Output.State.Status = 1 AND gAxis[AX_Y].Output.State.Status = 1 AND
				command[AX_X] = Axis_IDLE AND command[AX_Y] = Axis_IDLE AND
				fbAxisStatus[AX_X].StandStill = TRUE AND fbAxisStatus[AX_Y].StandStill = TRUE AND fbAxisStatus[AX_Z].StandStill = TRUE THEN
				
				IF gEquipment.Input.Parameter.ManualSlowMove THEN
					gEquipment.Input.Parameter.ManualSlowMove := FALSE;
					moveStep := 45;
				ELSE
					moveStep := 50;
				END_IF
			END_IF
			
		45: (* approach : fast to (target - SlowMoveLength) *)
			gAxis[AX_Z].Input.Parameter.Speed := gEquipment.Input.Parameter.SystemSpeed;
			gAxis[AX_Z].Input.Parameter.Position := gEquipment.Input.Parameter.ManualPositon[2] - SlowMoveLength;
			gAxis[AX_Z].Input.Command.Command := Axis_MOVE_ABSOLUTE;
			moveStep := 46;
			
		46:
			IF gAxis[AX_Z].Output.State.Status = 1 AND command[AX_Z] = Axis_IDLE AND fbAxisStatus[AX_Z].StandStill = TRUE THEN
				moveStep := 47;
			END_IF
			
		47: (* slow final approach *)
			gAxis[AX_Z].Input.Parameter.Speed := gEquipment.Input.Parameter.SystemSpeed * SlowMoveVelocity / 100;
			gAxis[AX_Z].Input.Parameter.Position := gEquipment.Input.Parameter.ManualPositon[2];
			gAxis[AX_Z].Input.Command.Command := Axis_MOVE_ABSOLUTE;
			moveStep := 60;
			
		50:
			gAxis[AX_Z].Input.Parameter.Speed := gEquipment.Input.Parameter.SystemSpeed;
			gAxis[AX_Z].Input.Parameter.Position := gEquipment.Input.Parameter.ManualPositon[2];
			gAxis[AX_Z].Input.Command.Command := Axis_MOVE_ABSOLUTE;
			moveStep := 60;
			
		60:
			IF gAxis[AX_Z].Output.State.Status = 1 AND command[AX_Z] = Axis_IDLE AND fbAxisStatus[AX_Z].StandStill = TRUE THEN
				moveStep := 100;
			END_IF
			
		100:
			gEquipment.Output.Status.ManualMove := FALSE;
			gEquipment.Output.Status.MoveComplete := TRUE;
	END_CASE
END_ACTION
