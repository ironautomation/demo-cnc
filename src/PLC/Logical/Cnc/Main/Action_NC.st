ACTION act_Halt:
	
	CASE commandStep OF
		0:
			fbCnc.Interrupt := TRUE;
			commandStep := 1;
		1:
			IF fbCnc.MoveInterrupted = TRUE THEN
				fbCnc.Interrupt := FALSE;
				commandStep := 2;
			END_IF
		2:
			;(* Complete *)
	END_CASE
END_ACTION

ACTION act_Stop:
	
	CASE commandStep OF
		0:
			gEquipment.Output.State.Stop := TRUE;
			programStarted := FALSE;
			fbCnc.Stop := fbCnc.PowerOn; (* nothing to stop without power *)
			commandStep := 1;
		1:
			IF fbCnc.InMotion = FALSE THEN
				fbCnc.Stop := FALSE;
				commandStep := 2;
			END_IF
		2:
			;(* Complete *)
	END_CASE
END_ACTION

ACTION act_Init:
	CASE commandStep OF
		0:
			stepTimer(IN := FALSE);

			IF fbCnc.Active = TRUE AND fbCnc.Info.CommunicationReady = TRUE THEN
				commandStep := 5;
			END_IF

		5:
			(* Power is level-sensitive and needs a new rising edge after an error : drop it for one cycle *)
			IF fbCnc.PowerOn = TRUE THEN
				commandStep := 100;
			ELSE
				fbCnc.Power := FALSE;
				commandStep := 10;
			END_IF

		10:
			fbCnc.Power := TRUE; (* powers all group axes *)
			stepTimer(IN := TRUE, PT := T#10s);

			IF fbCnc.PowerOn = TRUE THEN
				stepTimer(IN := FALSE);
				commandStep := 100;
			ELSIF fbCnc.Error OR stepTimer.Q THEN
				stepTimer(IN := FALSE);
				fbCnc.Power := FALSE;
				commandStep := 200;
			END_IF

		100:
			;(* Complete *)

		200:
			;(* power on failed - see gEquipment.Output.Status.Error / StatusID *)
	END_CASE
END_ACTION

ACTION act_Reset:
	CASE commandStep OF
		0:
			(* E-stop is cleared only once the button is released *)
			IF DI_MPG_Jog_EMS1 THEN
				emergencyLatched := FALSE;
			END_IF
			
			fbCnc.ErrorReset := TRUE;
			
			fbAxisReset[0].Execute := TRUE;
			fbAxisReset[1].Execute := TRUE;
			fbAxisReset[2].Execute := TRUE;
			
			commandStep := 10;
			
		10:
			IF NOT fbAxisReset[0].Busy AND NOT fbAxisReset[1].Busy AND NOT fbAxisReset[2].Busy THEN
				commandStep := 20;
			END_IF
			
		20:
			fbCnc.ErrorReset := FALSE;
			fbAxisReset[0].Execute := FALSE;
			fbAxisReset[1].Execute := FALSE;
			fbAxisReset[2].Execute := FALSE;
			stepTimer(IN := TRUE, PT := T#3s);

			IF fbCnc.Error = FALSE THEN
				stepTimer(IN := FALSE);
				commandStep := 100;
			ELSIF stepTimer.Q THEN
				(* error cause still present *)
				stepTimer(IN := FALSE);
				commandStep := 200;
			END_IF
		100:
			;(* Complete - servo stays off after an error : operator sends INIT *)
		200:
			;(* reset failed *)
	END_CASE
END_ACTION

ACTION act_Continue:
	CASE commandStep OF
		0:
			IF fbOptStop.Interrupting THEN
				fbOptStop.Continue := TRUE; (* standing at M01 - released in IDLE like fbCnc.Continue *)
			ELSIF fbCnc.MoveInterrupted OR lineStartWait THEN
				fbCnc.Continue := TRUE; (* HALT, single step : next block. Start at line : reposition / real run *)
			END_IF
			commandStep := 1;
		1:
			IF NOT fbCnc.MoveInterrupted THEN
				fbCnc.Continue := FALSE;
			END_IF
	END_CASE
END_ACTION

ACTION act_Home:
	CASE commandStep OF
		0:
			(* homing mode / home offsets are defined in the axis homing configuration. *)
			gEquipment.Output.State.Initialized := FALSE;

			IF fbCnc.PowerOn THEN
				fbCnc.Home := TRUE;
				commandStep := 5;
			ELSE
				commandStep := 200;
			END_IF

		5:
			IF fbCnc.CommandBusy = TRUE THEN
				commandStep := 10;
			ELSIF fbCnc.Error OR fbCnc.CommandAborted THEN
				fbCnc.Home := FALSE;
				commandStep := 200;
			END_IF

		10:
			IF fbCnc.IsHomed = TRUE AND fbCnc.CommandBusy = FALSE THEN
				fbCnc.Home := FALSE;
				commandStep := 20;
			ELSIF fbCnc.Error OR fbCnc.CommandAborted OR (fbCnc.CommandBusy = FALSE AND fbCnc.IsHomed = FALSE) THEN
				fbCnc.Home := FALSE;
				commandStep := 200;
			END_IF
			
		20:
			(* X axis mechanical deviation compensation - table from axis feature config *)
			fbMechDevCompX.Command := mcMDC_CMD_SWITCH_ON;
			fbMechDevCompX.Execute := TRUE;
			
			IF fbMechDevCompX.Done THEN
				fbMechDevCompX.Execute := FALSE;
				commandStep := 30;
			ELSIF fbMechDevCompX.Error THEN
				(* compensation feature not configured -> continue without it *)
				fbMechDevCompX.Execute := FALSE;
				commandStep := 30;
			END_IF
			
		30:
			(* a wait position after homing is up to the HMI (ManualPositon + ManualMove) *)
			commandStep := 50;
			
		50:
			gEquipment.Input.Command.AlarmClearAll := TRUE;
			gEquipment.Output.State.Initialized := TRUE;
			commandStep := 100;

		100:
			;

		200:
			;(* homing failed or servo off *)
	END_CASE
END_ACTION

ACTION act_Start:
	
	CASE commandStep OF
		0:
			stepTimer(IN := FALSE);
			gEquipment.Output.Status.WorkPanelName := gEquipment.Input.Parameter.sProgramName;
			CncParameters.ProgramName := gEquipment.Input.Parameter.sProgramName;
			CncParameters.MoveProgramOptions.InitProgram := gEquipment.Input.Parameter.sInitProgram;
			IF cncCommand = E_ACT_START_AT_LINE THEN
				(* start at the file line StartLine (1 = first, as C_CurrentLine) : mapp simulates the program up to that line, then moves
				   the axes to its start point by itself with single-axis moves. Cyclic puts the standard start point back once 15 is over *)
				CncParameters.MoveProgramOptions.StartPointType := mcPRGSP_LINE_NUMBER;
				CncParameters.MoveProgramOptions.StartPointParameter := UDINT_TO_LREAL(gCncRun.Input.StartLine);
				CncParameters.MoveProgramOptions.RepositioningParameter.Type := mcPRGRP_SINGLE_AXIS_AUTOMATIC;
				CncParameters.MoveProgramOptions.RepositioningParameter.AxisVelocityFactor := gCncRun.Input.ReposVelocityFactor;
			END_IF
			fbCnc.Update := TRUE;
			commandStep := 1;
			
		1:
			stepTimer(IN := TRUE, PT := T#5s);
			
			IF fbCnc.UpdateDone = TRUE THEN
				fbCnc.Update := FALSE;
				commandStep := 2;
			ELSIF stepTimer.Q THEN
				stepTimer(IN := FALSE);
				fbCnc.Update := FALSE;
				commandStep := 200;
			END_IF
			
		2:
			gEquipment.Output.State.Stop := FALSE;
			gEquipment.Output.State.Complete := FALSE;
			IF woNeed THEN
				(* work offset in use : set its frame first (act_WorkOffset) *)
				woStep := 1;
				commandStep := 5;
			ELSIF hoNeed THEN
				(* head offset in use : set its frame first (act_HeadOffset) *)
				hoStep := 1;
				commandStep := 6;
			ELSE
				commandStep := 10;
			END_IF
			
		5:
			IF woStep = 100 THEN
				IF hoNeed THEN
					(* head offset in use too : set its frame next (act_HeadOffset) *)
					hoStep := 1;
					commandStep := 6;
				ELSE
					commandStep := 10;
				END_IF
			ELSIF woStep = 200 THEN
				commandStep := 200; (* gWorkOffset.Output.Error / ErrorID *)
			END_IF
			
		6:
			IF hoStep = 100 THEN
				commandStep := 10;
			ELSIF hoStep = 200 THEN
				commandStep := 200; (* gHeadOffset.Output.Error / ErrorID *)
			END_IF
			
		10:
			fbCnc.MoveProgram := TRUE;
			programStarted := TRUE;
			lineStartRun := cncCommand = E_ACT_START_AT_LINE; (* FALSE for START *)
			commandStep := 20;
			
		20:
			IF fbCnc.MoveActive = TRUE THEN
				commandStep := 30;
			ELSIF fbCnc.Error = TRUE THEN
				fbCnc.MoveProgram := FALSE;
				commandStep := 200;
			ELSIF stepHold THEN
				(* single step / M01 / start at line waiting stopped the program before MoveActive was seen - see step 30 *)
				commandStep := 100;
			END_IF
			
		30:
			IF fbCnc.MoveDone = TRUE THEN
				fbCnc.MoveProgram := FALSE;
				gEquipment.Output.State.Complete := TRUE;
				commandStep := 100;
			ELSIF fbCnc.Error OR fbCnc.CommandAborted THEN
				(* program error / aborted while running *)
				fbCnc.MoveProgram := FALSE;
				commandStep := 200;
			ELSIF stepHold THEN
				(* single step / M01 / start at line waiting : the program waits for CONTINUE. Leave like after HALT so the mailbox takes CONTINUE -
				   MoveProgram stays set while the program is alive (IDLE branch), programEndTrig reports Complete at the end *)
				commandStep := 100;
			END_IF
			
		100:
			;(* Complete *)
			
		200:
			;(* load / start error *)
	END_CASE
	
END_ACTION

ACTION act_PowerOff:
	
	CASE commandStep OF
		0:
			stepTimer(IN := FALSE);
			fbCnc.Power := FALSE;
			commandStep := 10;
			
		10:
			stepTimer(IN := TRUE, PT := T#5s);
			
			IF fbCnc.PowerOn = FALSE THEN
				stepTimer(IN := FALSE);
				commandStep := 100;
			ELSIF stepTimer.Q THEN
				stepTimer(IN := FALSE);
				commandStep := 200;
			END_IF
			
		100:
			;(* Complete *)
			
		200:
			;(* servo did not switch off *)
	END_CASE
	
END_ACTION

ACTION act_MoveBlock:
	
	CASE commandStep OF
		0:
			stepTimer(IN := FALSE);
			programStarted := FALSE; (* an MDI block is not a production run *)
			CncParameters.Block := gEquipment.Input.Parameter.sBlock;
			fbCnc.Update := TRUE;
			commandStep := 1;
			
		1:
			stepTimer(IN := TRUE, PT := T#5s);
			
			IF fbCnc.UpdateDone = TRUE THEN
				stepTimer(IN := FALSE);
				fbCnc.Update := FALSE;
				IF woNeed THEN
					(* work offset in use : set its frame first (act_WorkOffset) *)
					woStep := 1;
					commandStep := 5;
				ELSIF hoNeed THEN
					(* head offset in use : set its frame first (act_HeadOffset) *)
					hoStep := 1;
					commandStep := 6;
				ELSE
					commandStep := 10;
				END_IF
			ELSIF stepTimer.Q THEN
				stepTimer(IN := FALSE);
				fbCnc.Update := FALSE;
				commandStep := 200;
			END_IF
			
		5:
			IF woStep = 100 THEN
				IF hoNeed THEN
					(* head offset in use too : set its frame next (act_HeadOffset) *)
					hoStep := 1;
					commandStep := 6;
				ELSE
					commandStep := 10;
				END_IF
			ELSIF woStep = 200 THEN
				commandStep := 200; (* gWorkOffset.Output.Error / ErrorID *)
			END_IF
			
		6:
			IF hoStep = 100 THEN
				commandStep := 10;
			ELSIF hoStep = 200 THEN
				commandStep := 200; (* gHeadOffset.Output.Error / ErrorID *)
			END_IF
			
		10:
			gEquipment.Output.State.Complete := FALSE;
			(* MoveDone / CommandAborted still set by an earlier move (e.g. a program that ended after HALT / CONTINUE,
			   when MoveProgram was already FALSE) are not this block's - step 20 ignores them until they fall *)
			mdiDoneOld := fbCnc.MoveDone;
			mdiAbortOld := fbCnc.CommandAborted;
			fbCnc.MoveBlock := TRUE;
			commandStep := 20;
			
		20:
			(* like act_Start : running first, then done. Not started within 5 s -> failed *)
			stepTimer(IN := TRUE, PT := T#5s);
			
			IF NOT fbCnc.MoveDone THEN
				mdiDoneOld := FALSE;
			END_IF
			IF NOT fbCnc.CommandAborted THEN
				mdiAbortOld := FALSE;
			END_IF
			
			IF fbCnc.MoveActive = TRUE THEN
				stepTimer(IN := FALSE);
				commandStep := 30;
			ELSIF fbCnc.MoveDone = TRUE AND NOT mdiDoneOld THEN
				(* short block already finished *)
				stepTimer(IN := FALSE);
				fbCnc.MoveBlock := FALSE;
				commandStep := 100;
			ELSIF fbCnc.Error OR (fbCnc.CommandAborted AND NOT mdiAbortOld) THEN
				stepTimer(IN := FALSE);
				fbCnc.MoveBlock := FALSE;
				commandStep := 200;
			ELSIF stepTimer.Q THEN
				stepTimer(IN := FALSE);
				fbCnc.MoveBlock := FALSE;
				commandStep := 200;
			END_IF
			
		30:
			IF fbCnc.MoveDone = TRUE THEN
				fbCnc.MoveBlock := FALSE;
				commandStep := 100;
			ELSIF fbCnc.Error OR fbCnc.CommandAborted THEN
				fbCnc.MoveBlock := FALSE;
				commandStep := 200;
			END_IF
			
		100:
			;(* Complete *)
			
		200:
			;(* block rejected or failed - see Output.Status.Error / StatusID *)
	END_CASE
	
END_ACTION
