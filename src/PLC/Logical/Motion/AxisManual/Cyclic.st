
PROGRAM _CYCLIC

	(* drive adapter PVs (Global.var) : referenced here so they are allocated on the target *)
	gDS402_X;
	gDS402_Y;
	gDS402_Z;

	(* copy the mappMotion position limits into gAxis[].Input.Parameter.SoftwareLimits* once after startup *)
	IF NOT cfgLimitLoaded THEN
		fbAxCfg.Name := cfgAxisName[cfgAxIdx];
		fbAxCfg.DataType := mcCFG_AX_MOVE_LIM;
		fbAxCfg.DataAddress := ADR(axMoveLim);
		fbAxCfg.Mode := mcPCM_LOAD;
		fbAxCfg.Execute := TRUE;
		fbAxCfg();

		IF fbAxCfg.Done OR fbAxCfg.Error THEN
			cfgLimitErrorID[cfgAxIdx] := fbAxCfg.ErrorID;
			IF fbAxCfg.Done THEN
				gAxis[cfgAxIdx].Input.Parameter.SoftwareLimitsNeg := LREAL_TO_DINT(axMoveLim.MovementLimits.Internal.Position.LowerLimit);
				gAxis[cfgAxIdx].Input.Parameter.SoftwareLimitsPos := LREAL_TO_DINT(axMoveLim.MovementLimits.Internal.Position.UpperLimit);
			END_IF
			fbAxCfg.Execute := FALSE;
			fbAxCfg();
			cfgAxIdx := cfgAxIdx + 1;
			cfgLimitLoaded := cfgAxIdx > AX_LAST;
		END_IF
	END_IF

	Torque_X := fbAxisTorque[AX_X].Torque;
	Torque_Y := fbAxisTorque[AX_Y].Torque;
	Torque_Z := fbAxisTorque[AX_Z].Torque;
	
	(* absolute positions are meaningless before homing *)
	allHomed := fbAxisInfo[AX_X].IsHomed AND fbAxisInfo[AX_Y].IsHomed AND fbAxisInfo[AX_Z].IsHomed;

	(* position move request of this scan : accepted or dropped below, reported by act_MoveResult *)
	moveReq := gEquipment.Input.Command.ManualMove;
	moveAccepted := FALSE;

	IF NOT DI_MPG_Jog_Enable AND gEquipment.Input.CncCommand = E_ACT_IDLE AND NOT gEquipment.Output.State.Move AND NOT DI_Auto AND NOT gEquipment.Output.Status.EmergencyStop THEN

		IF NOT allHomed THEN
			gEquipment.Input.Command.ManualMove := FALSE;
		END_IF
		
		IF gEquipment.Input.Command.ManualMove THEN
			gEquipment.Input.Command.ManualMove := FALSE;
			gEquipment.Output.Status.MoveComplete := FALSE;
			moveStep := 0;
			moveAccepted := TRUE;
		END_IF
		
		act_Jog;
	ELSE
		gEquipment.Output.Status.ManualMove := FALSE;
		gEquipment.Input.Command.ManualMove := FALSE; (* never run a stale move request later *)
	END_IF
	
	moveStepIn := moveStep;
	act_MovePosition;
	act_MoveResult; (* result to the HMI (gManualMoveResult) - reporting only *)
	
	(* per-axis POWER / HOME only while the CNC is idle *)
	cncIdle := gEquipment.Output.Status.CurrentAction = E_ACT_IDLE AND NOT gEquipment.Output.Status.ProgramActive;
	
	(* screen jog (Axis_JOG_POSITIVE / NEGATIVE) only in manual mode, without the handwheel and while no CNC command runs.
	   MOVE_ADDITIVE (one step) is not gated : the HMI uses it in auto mode too.
	   Not ProgramActive (cncIdle) : the axes group reports MoveActive for a cycle when a single axis starts to move, so every
	   jog would be dropped right after its start. A program only runs in auto mode, which NOT DI_Auto already keeps out *)
	jogAllowed := NOT DI_Auto AND NOT DI_MPG_Jog_Enable AND gEquipment.Output.Status.CurrentAction = E_ACT_IDLE;
	
	(* per-axis power is held by fbPower (Axis_POWER). E-stop and group servo off take the axes back *)
	IF gEquipment.Output.Status.EmergencyStop OR gEquipment.Output.Status.CurrentAction = E_ACT_POWER_OFF THEN
		FOR i := 0 TO AX_LAST BY 1 DO
			axisPowerReq[i] := FALSE;
		END_FOR
	END_IF
	
	(* jog watchdog : an HMI that changes gJogAlive while it jogs (every 0.1 s) gets the jog stopped when the value
	   stands still for 0.5 s (HMI hung, connection lost). An HMI that never changes it is not watched *)
	jogAny := jogPosActive[AX_X] OR jogNegActive[AX_X] OR jogPosActive[AX_Y] OR jogNegActive[AX_Y] OR jogPosActive[AX_Z] OR jogNegActive[AX_Z];
	IF NOT jogAny THEN
		jogAliveArmed := FALSE;
		jogAlivePrev := gJogAlive;
	ELSIF gJogAlive <> jogAlivePrev THEN
		jogAlivePrev := gJogAlive;
		jogAliveArmed := TRUE;
		jogAliveTimer(IN := FALSE); (* restart *)
	END_IF
	jogAliveTimer(IN := jogAny AND jogAliveArmed, PT := T#500ms);
	IF jogAliveTimer.Q THEN
		FOR i := 0 TO AX_LAST BY 1 DO
			jogPosActive[i] := FALSE;
			jogNegActive[i] := FALSE;
		END_FOR
		jogAliveArmed := FALSE;
	END_IF
	
	(* ---------- per-axis command handling ---------- *)
	FOR i := 0 TO AX_LAST BY 1 DO
		
		(* E-stop : stop whatever runs, accept only STOP / RESET *)
		IF gEquipment.Output.Status.EmergencyStop THEN
			IF gAxis[i].Input.Command.Command <> Axis_STOP AND gAxis[i].Input.Command.Command <> Axis_RESET THEN
				gAxis[i].Input.Command.Command := Axis_IDLE;
			END_IF
			IF (command[i] <> Axis_IDLE AND command[i] <> Axis_STOP AND command[i] <> Axis_RESET) OR jogPosActive[i] OR jogNegActive[i] THEN
				command[i] := Axis_STOP;
				commandStep[i] := 0;
			END_IF
		END_IF
		
		IF command[i] <> gAxis[i].Input.Command.Command AND command[i] = Axis_IDLE THEN
			gAxis[i].Output.State.Command := gAxis[i].Input.Command.Command;
			command[i] := gAxis[i].Input.Command.Command;
			gAxis[i].Input.Command.Command := Axis_IDLE;
			commandStep[i] := 0;
		ELSIF gAxis[i].Input.Command.Command = Axis_HALT AND command[i] <> Axis_IDLE THEN
			command[i] := gAxis[i].Input.Command.Command;
			gAxis[i].Input.Command.Command := Axis_IDLE;
			commandStep[i] := 0;
		ELSIF gAxis[i].Input.Command.Command = Axis_STOP AND command[i] <> Axis_IDLE THEN
			command[i] := gAxis[i].Input.Command.Command;
			gAxis[i].Input.Command.Command := Axis_IDLE;
			commandStep[i] := 0;
		END_IF
		
		(* a HALT / STOP ends a running position move (act_MovePosition never sends them itself) *)
		IF (command[i] = Axis_HALT OR command[i] = Axis_STOP) AND commandStep[i] = 0 AND moveStep < 100 THEN
			moveStep := 100;
		END_IF
		
		CASE command[i] OF
			Axis_IDLE:
				IF fbAxisInfo[i].IsHomed THEN
					gAxis[i].Output.State.Status := 1;
				ELSE
					gAxis[i].Output.State.Status := 0;
				END_IF
				
				gAxis[i].Output.State.Home := fbAxisInfo[i].IsHomed;
				
				(* keep jog active state while jogging (command returns to IDLE, motion continues) *)
				IF jogPosActive[i] OR jogNegActive[i] THEN
					gAxis[i].Output.State.Status := 2;
				END_IF
				
			Axis_HALT:
				CASE commandStep[i] OF
					0:
						IF (jogPosActive[i] OR jogNegActive[i]) AND NOT fbMoveAbs[i].Busy AND NOT fbMoveAdd[i].Busy AND NOT fbHome[i].Busy THEN
							(* jog only : the jog FB brakes by itself (Deceleration) when its request drops. MC_Halt would abort it,
							   and an aborted jog FB took no new jog until it was switched off and on *)
							jogPosActive[i] := FALSE;
							jogNegActive[i] := FALSE;
							fbMoveAbs[i].Execute := FALSE; (* not busy - released as in the MC_Halt path *)
							fbMoveAdd[i].Execute := FALSE;
							fbHome[i].Execute := FALSE;
							settleTimer[i](IN := FALSE);
							commandStep[i] := 2;
						ELSE
							jogPosActive[i] := FALSE;
							jogNegActive[i] := FALSE;
							fbMoveAbs[i].Execute := FALSE; (* release aborted moves so the next one gets a rising edge *)
							fbMoveAdd[i].Execute := FALSE;
							fbHome[i].Execute := FALSE;
							fbHalt[i].Execute := TRUE;
							settleTimer[i](IN := FALSE);
							commandStep[i] := 1;
						END_IF
					1:
						IF fbHalt[i].Done OR fbHalt[i].CommandAborted OR fbHalt[i].Error THEN
							fbHalt[i].Execute := FALSE;
							IF fbAxisStatus[i].StandStill OR fbAxisStatus[i].ErrorStop OR fbAxisStatus[i].Disabled THEN
								command[i] := Axis_IDLE;
							ELSE
								commandStep[i] := 2; (* status not yet standstill (read before the FB finished) *)
							END_IF
						END_IF
					2: (* wait for standstill (at most 2 s), then the channel is free again *)
						settleTimer[i](IN := TRUE, PT := T#2s);
						IF fbAxisStatus[i].StandStill OR fbAxisStatus[i].ErrorStop OR fbAxisStatus[i].Disabled OR settleTimer[i].Q THEN
							settleTimer[i](IN := FALSE);
							command[i] := Axis_IDLE;
						END_IF
				END_CASE
				
			Axis_HOME:
				(* single-axis homing with the homing settings of the axis configuration.
				   Group homing (Z first, then XY) is HOME / INIT in gEquipment.Input.CncCommand *)
				CASE commandStep[i] OF
					0:
						IF NOT cncIdle OR gEquipment.Output.Status.EmergencyStop OR NOT fbAxisInfo[i].PowerOn THEN
							command[i] := Axis_IDLE; (* rejected *)
						ELSE
							jogPosActive[i] := FALSE;
							jogNegActive[i] := FALSE;
							fbHome[i].HomingMode := mcHOMING_DEFAULT;
							fbHome[i].Execute := TRUE;
							gAxis[i].Output.State.Status := 2;
							commandStep[i] := 1;
						END_IF
					1:
						IF fbHome[i].Done OR fbHome[i].Error OR fbHome[i].CommandAborted THEN
							fbHome[i].Execute := FALSE;
							command[i] := Axis_IDLE;
						END_IF
				END_CASE
				
			Axis_POWER:
				(* gAxis[i].Input.Parameter.Power : TRUE = on, FALSE = off *)
				CASE commandStep[i] OF
					0:
						IF NOT cncIdle OR (gAxis[i].Input.Parameter.Power AND gEquipment.Output.Status.EmergencyStop) THEN
							command[i] := Axis_IDLE; (* rejected *)
						ELSIF gAxis[i].Input.Parameter.Power THEN
							axisPowerReq[i] := TRUE;
							commandStep[i] := 10;
						ELSIF NOT (fbAxisStatus[i].StandStill OR fbAxisStatus[i].Disabled OR fbAxisStatus[i].ErrorStop) THEN
							command[i] := Axis_IDLE; (* rejected : axis moving *)
						ELSE
							(* MC_Power switches off only on a falling Enable : take the axis first, then release it *)
							axisPowerReq[i] := TRUE;
							commandStep[i] := 20;
						END_IF
					10: (* on *)
						IF fbPower[i].Status OR fbPower[i].Error THEN
							command[i] := Axis_IDLE;
						END_IF
					20: (* off *)
						IF fbPower[i].Status OR fbPower[i].Error THEN
							axisPowerReq[i] := FALSE;
							commandStep[i] := 21;
						END_IF
					21:
						IF NOT fbAxisInfo[i].PowerOn OR fbPower[i].Error THEN
							command[i] := Axis_IDLE;
						END_IF
				END_CASE
				
			Axis_JOG_NEGATIVE:
				CASE commandStep[i] OF
					0:
						IF gAxis[i].Input.Parameter.JogSpeed = 0 THEN
							gAxis[i].Input.Parameter.JogSpeed := 50;
						END_IF
						
						IF NOT jogAllowed THEN
							command[i] := Axis_IDLE; (* rejected : auto mode, handwheel or CNC busy *)
						ELSIF jogFault[i] THEN
							jogFault[i] := FALSE; (* jog FB back on this scan - the jog request waits until it is ready (step 2) *)
							settleTimer[i](IN := FALSE);
							commandStep[i] := 2;
						ELSE
							gAxis[i].Output.State.JogNegative := TRUE;
							jogNegActive[i] := TRUE;
							jogPosActive[i] := FALSE;
							gAxis[i].Output.State.Status := 2;
							commandStep[i] := 1;
						END_IF
					1:
						command[i] := Axis_IDLE;
						commandStep[i] := 0;
					2: (* a request set before the FB reports Ready is not seen - the jog did not start *)
						settleTimer[i](IN := TRUE, PT := T#1s);
						IF fbJog[i].Ready OR settleTimer[i].Q THEN
							settleTimer[i](IN := FALSE);
							gAxis[i].Output.State.JogNegative := TRUE;
							jogNegActive[i] := TRUE;
							jogPosActive[i] := FALSE;
							gAxis[i].Output.State.Status := 2;
							commandStep[i] := 1;
						END_IF
				END_CASE
				
			Axis_JOG_POSITIVE:
				CASE commandStep[i] OF
					0:
						IF gAxis[i].Input.Parameter.JogSpeed = 0 THEN
							gAxis[i].Input.Parameter.JogSpeed := 50;
						END_IF
						
						IF NOT jogAllowed THEN
							command[i] := Axis_IDLE; (* rejected : auto mode, handwheel or CNC busy *)
						ELSIF jogFault[i] THEN
							jogFault[i] := FALSE; (* jog FB back on this scan - the jog request waits until it is ready (step 2) *)
							settleTimer[i](IN := FALSE);
							commandStep[i] := 2;
						ELSE
							gAxis[i].Output.State.JogPositive := TRUE;
							jogPosActive[i] := TRUE;
							jogNegActive[i] := FALSE;
							gAxis[i].Output.State.Status := 2;
							commandStep[i] := 1;
						END_IF
					1:
						command[i] := Axis_IDLE;
						commandStep[i] := 0;
					2: (* a request set before the FB reports Ready is not seen - the jog did not start *)
						settleTimer[i](IN := TRUE, PT := T#1s);
						IF fbJog[i].Ready OR settleTimer[i].Q THEN
							settleTimer[i](IN := FALSE);
							gAxis[i].Output.State.JogPositive := TRUE;
							jogPosActive[i] := TRUE;
							jogNegActive[i] := FALSE;
							gAxis[i].Output.State.Status := 2;
							commandStep[i] := 1;
						END_IF
				END_CASE
				
			Axis_MOVE_ABSOLUTE:
				CASE commandStep[i] OF
					0:
						IF NOT fbAxisInfo[i].IsHomed THEN
							(* absolute target without homing : reject *)
							command[i] := Axis_IDLE;
						ELSE
							fbMoveAbs[i].Position := gAxis[i].Input.Parameter.Position;
							fbMoveAbs[i].Velocity := gAxis[i].Input.Parameter.Speed; (* [mm/s] *)
							gAxis[i].Output.State.Status := 2;
							fbMoveAbs[i].Execute := TRUE;
							commandStep[i] := 1;
						END_IF
					1:
						IF fbMoveAbs[i].Done THEN
							fbMoveAbs[i].Execute := FALSE;
							command[i] := Axis_IDLE;
							commandStep[i] := 0;
						ELSIF fbMoveAbs[i].CommandAborted OR fbMoveAbs[i].Error THEN
							fbMoveAbs[i].Execute := FALSE;
							command[i] := Axis_IDLE;
							commandStep[i] := 0;
						END_IF
				END_CASE
				
			Axis_MOVE_ADDITIVE:
				CASE commandStep[i] OF
					0:
						gAxis[i].Output.State.Status := 2;
						fbMoveAdd[i].Distance := gAxis[i].Input.Parameter.Distance;
						fbMoveAdd[i].Velocity := gAxis[i].Input.Parameter.Speed;
						fbMoveAdd[i].Execute := TRUE;
						settleTimer[i](IN := FALSE);
						commandStep[i] := 1;
					1:
						IF fbMoveAdd[i].Done OR fbMoveAdd[i].CommandAborted OR fbMoveAdd[i].Error THEN
							fbMoveAdd[i].Execute := FALSE;
							IF fbAxisStatus[i].StandStill OR fbAxisStatus[i].ErrorStop OR fbAxisStatus[i].Disabled THEN
								command[i] := Axis_IDLE;
							ELSE
								commandStep[i] := 2; (* status not yet standstill (read before the FB finished) *)
							END_IF
						END_IF
					2: (* wait for standstill (at most 2 s), then the channel is free again *)
						settleTimer[i](IN := TRUE, PT := T#2s);
						IF fbAxisStatus[i].StandStill OR fbAxisStatus[i].ErrorStop OR fbAxisStatus[i].Disabled OR settleTimer[i].Q THEN
							settleTimer[i](IN := FALSE);
							command[i] := Axis_IDLE;
						END_IF
				END_CASE
				
			Axis_RESET:
				CASE commandStep[i] OF
					0:
						fbReset[i].Execute := TRUE;
						commandStep[i] := 1;
					1:
						IF fbReset[i].Done OR fbReset[i].Error THEN
							(* release even if the error remains - Output.State.Error shows it, a new RESET can be sent *)
							fbReset[i].Execute := FALSE;
							command[i] := Axis_IDLE;
						END_IF
				END_CASE
				
			Axis_STOP:
				CASE commandStep[i] OF
					0:
						jogPosActive[i] := FALSE;
						jogNegActive[i] := FALSE;
						fbMoveAbs[i].Execute := FALSE; (* release aborted moves so the next one gets a rising edge *)
						fbMoveAdd[i].Execute := FALSE;
						fbHome[i].Execute := FALSE;
						fbStop[i].Execute := TRUE;
						settleTimer[i](IN := FALSE);
						commandStep[i] := 1;
					1:
						IF fbStop[i].Done OR fbStop[i].Error THEN
							fbStop[i].Execute := FALSE;
							IF fbAxisStatus[i].StandStill OR fbAxisStatus[i].ErrorStop OR fbAxisStatus[i].Disabled THEN
								command[i] := Axis_IDLE;
							ELSE
								commandStep[i] := 2; (* MC_Stop holds the axis in Stopping until Execute falls *)
							END_IF
						END_IF
					2: (* wait for standstill (at most 2 s), then the channel is free again *)
						settleTimer[i](IN := TRUE, PT := T#2s);
						IF fbAxisStatus[i].StandStill OR fbAxisStatus[i].ErrorStop OR fbAxisStatus[i].Disabled OR settleTimer[i].Q THEN
							settleTimer[i](IN := FALSE);
							command[i] := Axis_IDLE;
						END_IF
				END_CASE

			ELSE
				(* Axis_MOVE_VELOCITY / unknown : not implemented - release so the axis channel is not locked *)
				command[i] := Axis_IDLE;
		END_CASE
		
		(* no jog during an E-stop *)
		IF gEquipment.Output.Status.EmergencyStop THEN
			jogPosActive[i] := FALSE;
			jogNegActive[i] := FALSE;
		END_IF
		
		(* auto mode, handwheel selected or a CNC command / program : a running screen jog stops too - the jog FB brakes
		   by itself (Deceleration) when its request drops, as on a HALT of a pure jog or the jog watchdog *)
		IF NOT jogAllowed THEN
			jogPosActive[i] := FALSE;
			jogNegActive[i] := FALSE;
		END_IF
		
		(* jog FB error or aborted (by MC_Halt / MC_Stop / a move / homing on the axis) : drop the jog and switch the FB off -
		   it leaves that state only on a falling Enable and took no new jog before (jog worked only now and then).
		   The next jog command switches it on again (no on/off toggling while the cause stays) *)
		IF fbJog[i].Error OR fbJog[i].CommandAborted THEN
			jogFault[i] := TRUE;
			jogPosActive[i] := FALSE;
			jogNegActive[i] := FALSE;
		END_IF
		
		(* while this axis jogs its speed follows the HMI (joystick tilt) - act_Jog copies it only while State.Move is FALSE *)
		IF (jogPosActive[i] OR jogNegActive[i]) AND gAxis[i].Input.Parameter.JogSpeed > 0 THEN
			JogSpeed[i] := gAxis[i].Input.Parameter.JogSpeed;
		END_IF
		
		(* jog FB : level controlled *)
		fbJog[i].Velocity := JogSpeed[i];
		fbJog[i].JogPositive := jogPosActive[i];
		fbJog[i].JogNegative := jogNegActive[i];
		fbJog[i].Enable := fbAxisInfo[i].PowerOn AND NOT jogFault[i];
		
		IF NOT jogPosActive[i] THEN
			gAxis[i].Output.State.JogPositive := FALSE;
		END_IF
		IF NOT jogNegActive[i] THEN
			gAxis[i].Output.State.JogNegative := FALSE;
		END_IF
		
		(* status to HMI - positions/velocities in measurement units [mm], [mm/s] *)
		gAxis[i].Output.State.Enable := fbAxisInfo[i].PowerOn;
		gAxis[i].Output.State.Position := fbAxisPosition[i].Position;
		gAxis[i].Output.State.Speed := fbAxisVelocity[i].Velocity;
		gAxis[i].Output.State.Error := fbAxisStatus[i].ErrorStop;
		gAxis[i].Output.State.ErrorID := DINT_TO_UDINT(fbAxisError[i].AxisErrorID);
		
		IF fbAxisStatus[i].ErrorStop THEN
			gAxis[i].Output.State.Status := 3;
		END_IF
		
		(* drive diagnosis to HMI (read only) - copies of the MC_ReadAxisInfo above, no new FB on the axis *)
		gDriveDiag[i].Valid := fbAxisInfo[i].Valid;
		gDriveDiag[i].CommReady := fbAxisInfo[i].CommunicationReady;
		gDriveDiag[i].ReadyForPowerOn := fbAxisInfo[i].ReadyForPowerOn;
		gDriveDiag[i].Warning := fbAxisInfo[i].AxisWarning;
		
		(* warning-level alarm (alarms.json exType 1) : filtered so one warning gives one alarm - display only, no reaction *)
		warnOnTimer[i](IN := gDriveDiag[i].Valid AND gDriveDiag[i].CommReady AND gDriveDiag[i].Warning, PT := T#500ms);
		warnHoldTimer[i](IN := warnOnTimer[i].Q, PT := T#2s);
		gDriveDiag[i].WarningAlarm := warnHoldTimer[i].Q;
		
		(* FB calls *)
		fbAxisInfo[i]();
		fbAxisStatus[i]();
		fbAxisPosition[i]();
		fbAxisVelocity[i]();
		fbAxisTorque[i]();
		fbAxisError[i]();
		fbMoveAbs[i]();
		fbMoveAdd[i]();
		fbJog[i]();
		fbStop[i]();
		fbHalt[i]();
		fbReset[i]();
		fbPower[i].Enable := axisPowerReq[i];
		fbPower[i]();
		fbHome[i]();
		
	END_FOR
	
END_PROGRAM
