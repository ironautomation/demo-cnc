
PROGRAM _CYCLIC

	(* Feedrate override from HMI *)
	IF gEquipment.Input.Parameter.Feedrate > 0.0 THEN
		fbCnc.FeedrateOverride := gEquipment.Input.Parameter.Feedrate;
	END_IF
	
	(* ---------- emergency stop ----------
	   MPG E-stop button, NC contact (FALSE = pressed). Software reaction only - NOT a safety circuit.
	   Stops the CNC and all single-axis motion, then powers off; discharge / laser off.
	   Latched until the button is released and RESET is sent. *)
	IF NOT DI_MPG_Jog_EMS1 THEN
		IF NOT emergencyLatched THEN
			cncCommand := E_ACT_STOP;
			commandStep := 0;
		END_IF
		emergencyLatched := TRUE;
		bootPowerDone := TRUE; (* no automatic power-on after the E-stop *)
	END_IF

	(* power on once after boot (servo only - homing is always an operator command) *)
	IF NOT bootPowerDone AND cncCommand = E_ACT_IDLE AND fbCnc.Active AND fbCnc.Info.ReadyToPowerOn THEN
		bootPowerDone := TRUE;
		initThenHome := FALSE;
		cncCommand := E_ACT_INIT;
		commandStep := 0;
	END_IF

	(* single step / optional stop (M01) from the HMI (gCncRun, both FALSE unless the HMI sets them).
	   Single step not for an MDI block (act_MoveBlock waits for MoveDone) *)
	fbCnc.SingleStep := gCncRun.Input.SingleStep AND cncCommand <> E_ACT_MOVE_BLOCK;
	fbOptStop.Enable := gCncRun.Input.OptionalStop;

	(* start at line : before its real run the program is simulated up to the start line, the axes are repositioned and it may wait for CONTINUE.
	   These phases count only in a run started by E_ACT_START_AT_LINE (lineStartRun), so START and MDI are not touched.
	   STOP, RESET, E-stop and an error end it, so an aborted start at line never blocks the next command *)
	IF cncCommand = E_ACT_STOP OR cncCommand = E_ACT_RESET OR emergencyLatched OR fbCnc.Error THEN
		lineStartRun := FALSE;
	END_IF
	lineStartPrep := lineStartRun AND fbCnc.Info.Program.ProgramPhase <> mcPRGPH_INACTIVE AND fbCnc.Info.Program.ProgramPhase <> mcPRGPH_REAL_RUN;
	lineStartWait := lineStartRun AND (fbCnc.Info.Program.ProgramPhase = mcPRGPH_WAIT_FOR_AXES_REPOS OR fbCnc.Info.Program.ProgramPhase = mcPRGPH_WAIT_FOR_REAL_RUN);

	(* program held : waits for CONTINUE - interrupted (HALT, single step), standing at M01 (fbOptStop.Interrupting is FALSE while OptionalStop is off)
	   or a start at line waiting before its real run *)
	programHeld := fbCnc.MoveInterrupted OR fbOptStop.Interrupting OR lineStartWait;

	(* program alive : running or paused (HALT). MoveActive alone is not enough - it falls on HALT,
	   so the HMI would see the run as ended and the next START would run the program from the top. A paused program counts as running everywhere below *)
	programAlive := fbCnc.MoveActive OR programHeld OR lineStartPrep;
	IF NOT programAlive AND cncCommand <> E_ACT_START_AT_LINE THEN
		lineStartRun := FALSE;
	END_IF

	(* the program stopped by itself (single step after a block, M01, start at line waiting) : act_Start leaves like after HALT so the mailbox takes CONTINUE *)
	stepHold := (fbCnc.MoveInterrupted AND fbCnc.SingleStep) OR fbOptStop.Interrupting OR lineStartWait;

	(* ---------- command preconditions ---------- *)
	CASE gEquipment.Input.CncCommand OF
		E_ACT_START: (* homing is mandatory after every power-up *)
			cmdAllowed := fbCnc.PowerOn AND fbCnc.IsHomed AND DI_Auto AND NOT programAlive;
		E_ACT_START_AT_LINE: (* like START, line 1 or later *)
			cmdAllowed := fbCnc.PowerOn AND fbCnc.IsHomed AND DI_Auto AND NOT programAlive AND gCncRun.Input.StartLine >= 1;
		E_ACT_HOME:
			cmdAllowed := fbCnc.PowerOn AND NOT programAlive;
		E_ACT_HALT:
			cmdAllowed := fbCnc.MoveActive AND NOT fbCnc.MoveInterrupted;
		E_ACT_CONTINUE: (* after HALT, a single step or M01 *)
			cmdAllowed := programHeld;
		E_ACT_POWER_OFF:
			cmdAllowed := NOT fbCnc.InMotion AND NOT programAlive;
		E_ACT_MOVE_BLOCK:
			cmdAllowed := fbCnc.PowerOn AND fbCnc.IsHomed AND NOT programAlive;
		E_ACT_MEASURE_Z: (* Z reference : manual mode, homed, every axis idle without error, no handwheel, valid gZRef.Input, sensor off *)
			cmdAllowed := fbCnc.PowerOn AND fbCnc.IsHomed AND NOT DI_Auto AND NOT programAlive AND NOT fbCnc.InMotion
				AND NOT DI_MPG_Jog_Enable AND gZRef.Output.ParamOk AND NOT DI_ZRef_Sensor
				AND gAxis[AX_X].Output.State.Status = 1 AND gAxis[AX_Y].Output.State.Status = 1 AND gAxis[AX_Z].Output.State.Status = 1;
		E_ACT_INIT, E_ACT_STOP, E_ACT_RESET, E_ACT_LOADPROGRAM:
			cmdAllowed := TRUE;
		ELSE (* a value without an action (ABORT while idle, unknown) : refused, so it never blocks the mailbox *)
			cmdAllowed := FALSE;
	END_CASE

	(* during an E-stop only STOP / RESET / servo off are accepted *)
	IF emergencyLatched AND gEquipment.Input.CncCommand <> E_ACT_STOP AND gEquipment.Input.CncCommand <> E_ACT_RESET AND gEquipment.Input.CncCommand <> E_ACT_POWER_OFF THEN
		cmdAllowed := FALSE;
	END_IF

	(* ---------- command arbitration ---------- *)
	IF cncCommand <> gEquipment.Input.CncCommand AND cncCommand = E_ACT_IDLE THEN

		IF cmdAllowed THEN

			cncCommand := gEquipment.Input.CncCommand;
			initThenHome := TRUE; (* INIT from HMI = power + homing *)
			gEquipment.Output.Status.Rejected := E_ACT_IDLE;
			gEquipment.Input.CncCommand := E_ACT_IDLE;
			commandStep := 0;
		ELSE
			gEquipment.Output.Status.Rejected := gEquipment.Input.CncCommand;
			gEquipment.Input.CncCommand := E_ACT_IDLE;
		END_IF

	ELSIF gEquipment.Input.CncCommand = E_ACT_HALT AND cmdAllowed AND (cncCommand = E_ACT_START OR cncCommand = E_ACT_CONTINUE OR cncCommand = E_ACT_START_AT_LINE) THEN
		
		cncCommand := gEquipment.Input.CncCommand;
		gEquipment.Input.CncCommand := E_ACT_IDLE;
		commandStep := 0;
		
	ELSIF gEquipment.Input.CncCommand = E_ACT_STOP AND cncCommand <> E_ACT_IDLE AND cncCommand <> E_ACT_INIT THEN
		
		cncCommand := gEquipment.Input.CncCommand;
		gEquipment.Input.CncCommand := E_ACT_IDLE;
		commandStep := 0;
		
	ELSIF cncCommand <> E_ACT_IDLE AND gEquipment.Input.CncCommand = E_ACT_ABORT THEN
		
		gEquipment.Input.CncCommand := E_ACT_IDLE;
		cncCommand := E_ACT_IDLE;
		
	ELSIF cncCommand <> E_ACT_IDLE THEN
		
		gEquipment.Input.CncCommand := E_ACT_IDLE;
		
	END_IF
	
	(* work offset G54..G57 : Apply from the HMI, frame SCS1 set before a run (only when an offset is in use) *)
	act_WorkOffset;
	
	(* head offset : Apply from the HMI, frame SCS2 set before a run (only when an offset is in use) *)
	act_HeadOffset;
	
	(* program start point : from the top (the B&R defaults), except while E_ACT_START_AT_LINE starts a program (act_Start step 0),
	   so START and MDI never inherit a start line through fbCnc.Update *)
	IF cncCommand <> E_ACT_START_AT_LINE THEN
		CncParameters.MoveProgramOptions.StartPointType := mcPRGSP_STANDARD;
		CncParameters.MoveProgramOptions.StartPointParameter := 0.0;
		CncParameters.MoveProgramOptions.RepositioningParameter.Type := mcPRGRP_SINGLE_AXIS;
		CncParameters.MoveProgramOptions.RepositioningParameter.AxisVelocityFactor := 0.0;
	END_IF

	(* ---------- command execution ---------- *)
	CASE cncCommand OF
		
		E_ACT_IDLE:
			
			commandStep := 0;
			
			(* release all pulse-type CNC commands - MoveProgram only once the program has ended : a paused program must stay loaded for CONTINUE *)
			fbCnc.Home := FALSE;
			IF NOT programAlive THEN
				fbCnc.MoveProgram := FALSE;
			END_IF
			fbCnc.MoveBlock := FALSE;
			fbCnc.Interrupt := FALSE;
			fbCnc.Continue := FALSE;
			fbOptStop.Continue := FALSE;
			fbCnc.Stop := FALSE;
			fbCnc.ErrorReset := FALSE;
			fbCnc.Update := FALSE;
			fbAxisReset[0].Execute := FALSE;
			fbAxisReset[1].Execute := FALSE;
			fbAxisReset[2].Execute := FALSE;
			
			stepTimer(IN := FALSE);

		E_ACT_INIT:
			
			act_Init;

			IF commandStep = 100 THEN
				commandStep := 0;
				IF initThenHome AND NOT fbCnc.IsHomed THEN
					cncCommand := E_ACT_HOME;
				ELSE
					cncCommand := E_ACT_IDLE;
				END_IF
			ELSIF commandStep = 200 THEN
				cncCommand := E_ACT_IDLE;
			END_IF
			
		E_ACT_LOADPROGRAM: (* Load CNC Program *)
			
			cncCommand := E_ACT_IDLE;
			
		E_ACT_START: (* Execute CNC *)
			
			act_Start;

			IF commandStep = 100 THEN
				cncCommand := E_ACT_IDLE;
			ELSIF commandStep = 200 THEN
				cncCommand := E_ACT_IDLE;
			END_IF
			
		E_ACT_START_AT_LINE: (* Execute CNC from the file line gCncRun.Input.StartLine - act_Start sets the start point *)
			
			act_Start;
			
			IF commandStep = 100 OR commandStep = 200 THEN
				cncCommand := E_ACT_IDLE;
			END_IF
			
		E_ACT_RESET: (* CNC Reset *)
			
			act_Reset;

			IF commandStep = 100 OR commandStep = 200 THEN
				cncCommand := E_ACT_IDLE;
			END_IF
			
		E_ACT_HOME:
			
			IF NOT fbCnc.InMotion THEN
				act_Home;
			END_IF

			IF commandStep = 100 OR commandStep = 200 THEN
				cncCommand := E_ACT_IDLE;
			END_IF
			
		E_ACT_HALT: (* CNC Halt *)
			
			act_Halt;
			
			IF commandStep = 2 THEN
				commandStep := 0;
				cncCommand := E_ACT_IDLE;
			END_IF
			
		E_ACT_CONTINUE: (* CNC Continue *)
			
			act_Continue;
			
			IF commandStep = 1 THEN
				commandStep := 0;
				cncCommand := E_ACT_IDLE;
			END_IF
			
		E_ACT_STOP: (* CNC Stop *)
			
			act_Stop;

			IF commandStep = 2 THEN
				commandStep := 0;
				cncCommand := E_ACT_IDLE;
			END_IF
			
		E_ACT_POWER_OFF: (* Servo off *)
			
			act_PowerOff;
			
			IF commandStep = 100 OR commandStep = 200 THEN
				cncCommand := E_ACT_IDLE;
			END_IF
			
		E_ACT_MOVE_BLOCK: (* MDI : single NC block *)
			
			act_MoveBlock;
			
			IF commandStep = 100 OR commandStep = 200 THEN
				cncCommand := E_ACT_IDLE;
			END_IF
			
		E_ACT_MEASURE_Z: (* Z reference measurement : result in gZRef.Output *)
			
			act_MeasureZ;
			
			IF commandStep = 100 OR commandStep = 200 THEN
				cncCommand := E_ACT_IDLE;
			END_IF
			
	END_CASE
	
	(* Z reference : input check, a measurement left by STOP / ABORT / E-stop / handwheel is braked, status *)
	act_ZRef;
	

	(* program finished : also after HALT / CONTINUE, when act_Start is no longer running and cannot see MoveDone.
	   The program ends without STOP, error or interruption -> Complete *)
	programEndTrig(CLK := programAlive);
	IF programEndTrig.Q AND programStarted THEN
		IF NOT fbCnc.Error AND NOT fbCnc.MoveInterrupted AND NOT gEquipment.Output.State.Stop THEN
			gEquipment.Output.State.Complete := TRUE;
		END_IF
		programStarted := FALSE;
	END_IF
	
	(* LaserPower set by a program or an MDI line (path synchronous alias) holds for that run only *)
	IF programEndTrig.Q THEN
		C_LaserPower := -1.0;
	END_IF
	
	(* E-stop : power off once the axes have stopped (at the latest after 2 s) *)
	emergencyTimer(IN := emergencyLatched, PT := T#2s);
	IF emergencyLatched AND (NOT fbCnc.InMotion OR emergencyTimer.Q) THEN
		fbCnc.Power := FALSE;
	END_IF
	
	(* ---------- status to HMI ---------- *)
	gEquipment.Output.Status.CurrentAction := cncCommand;
	gEquipment.Output.Status.Mode := DI_Auto;
	gEquipment.Output.State.Move := fbCnc.InMotion;
	gEquipment.Output.Status.PowerOn := fbCnc.PowerOn;
	gEquipment.Output.Status.IsHomed := fbCnc.IsHomed;
	gEquipment.Output.Status.ProgramActive := programAlive; (* TRUE while paused too - HMI, OpMode, AxisManual (idle), Laser read it *)
	gEquipment.Output.Status.ProgramInterrupted := programHeld; (* HALT, single step or M01 : the HMI offers CONTINUE *)
	gEquipment.Output.Status.Error := fbCnc.Error;
	gEquipment.Output.Status.StatusID := fbCnc.StatusID;
	gEquipment.Output.Status.EmergencyStop := emergencyLatched;
	C_CurrentLine := UDINT_TO_DINT(fbCnc.Info.Program.ProgramMonitor.LineNumber);
	C_OverallRuntime := fbCnc.Info.Program.ProgramMonitor.OverallRuntime; (* HMI : remaining time, elapsed time *)
	C_MovementRuntime := fbCnc.Info.Program.ProgramMonitor.MovementRuntime;
	gHeadSupport := SHL(UDINT#1, HEAD_DISPENSER) OR SHL(UDINT#1, HEAD_LASER); (* heads of this PLC program - fixed, set every cycle so a write over OPC UA does not stay *)
	gCncRun.Output.SingleStepActive := fbCnc.SingleStepActive;
	gCncRun.Output.OptionalStopActive := fbOptStop.Interrupting;
	gCncRun.Output.OptionalStopErrorId := fbOptStop.ErrorID;
	gCncRun.Output.InterruptStatus := fbCnc.Info.Program.InterruptStatus;
	gCncRun.Output.ProgramPhase := fbCnc.Info.Program.ProgramPhase;

	(* ---------- M functions ---------- *)
	mfClear := NOT programAlive OR emergencyLatched; (* no program / E-stop : M42, M62 act as if set - not while paused, M41 / M61 come back after CONTINUE *)
	
	act_HeadCheck; (* only the M functions and manual on of the active head (gActiveHead) - 0 = no check *)
	
	act_M41;
	act_M42;
	act_M44;
	act_M45;
	act_MSpare; (* M50..M59 : no function, go on at once *)
	act_M61;
	act_M62;
	
	(* HALT, single step, M01 : output off while the program is held, back on after CONTINUE (M41 / M61 Value stays set) *)
	IF programHeld THEN
		gDispenser.Input.Command.Discharge := FALSE;
		gLaser.Input.Command.Emission := FALSE;
	END_IF
	
	IF emergencyLatched THEN
		gDispenser.Input.Command.Manual := FALSE;
		gLaser.Input.Command.Manual := FALSE;
	END_IF

	(* ---------- FB calls ---------- *)
	fbCnc();
	fbOptStop();

	FOR i := 0 TO 7 DO
		fbMFunction[i]();
		fbMFunctionSpare[i]();
	END_FOR
	
	FOR i := 0 TO 2 DO
		fbAxisReset[i]();
	END_FOR
	
	fbMechDevCompX();
	

	FOR i := 0 TO 2 DO
		fbZrMove[i]();
		fbZrHalt[i]();
	END_FOR
	fbWorkFrame();
	fbHeadFrame();
	
END_PROGRAM
