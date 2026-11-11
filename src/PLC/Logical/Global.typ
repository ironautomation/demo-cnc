
TYPE
	Equip_Type : 	STRUCT
		Input : EquipInput_Type;
		Output : EquipOutput_Type;
	END_STRUCT;
	EquipInput_Type : 	STRUCT
		Command : EquipInputCommand_Type;
		CncCommand : E_CNC_ACTION;
		Parameter : EquipInputParameter_Type;
	END_STRUCT;
	EquipOutput_Type : 	STRUCT
		State : EquipOutputState_Type;
		Status : EquipOutputStatus_Type;
	END_STRUCT;
	EquipInputCommand_Type : 	STRUCT
		ManualMove : BOOL; (*move to Parameter.ManualPositon (Z retracts to 0 first) - manual mode, homed*)
		AlarmClearAll : BOOL;
		ManualMode : BOOL; (*TRUE = manual mode (jog, position move, manual discharge). Ignored while the CNC is busy*)
	END_STRUCT;
	EquipInputParameter_Type : 	STRUCT
		sProgramName : STRING[80];
		DryRun : BOOL;
		SystemSpeed : REAL;
		Feedrate : REAL;
		ManualSlowMove : BOOL;
		ManualPositon : ARRAY[0..2]OF REAL;
		sBlock : STRING[260]; (*single NC block for E_ACT_MOVE_BLOCK (MDI), e.g. 'G90 G01 X10 Y20 F1000'*)
		sInitProgram : STRING[80]; (*init program run before every program START (not MDI) as an init subroutine of the program (MoveProgramOptions.InitProgram), e.g. a G92 or a move to a teach position. Empty = none*)
	END_STRUCT;
	EquipOutputState_Type : 	STRUCT
		Initialized : BOOL;
		Stop : BOOL;
		Move : BOOL;
		Complete : BOOL;
	END_STRUCT;
	EquipOutputStatus_Type : 	STRUCT
		CurrentAction : E_CNC_ACTION;
		Mode : BOOL;
		ManualMove : BOOL;
		MoveComplete : BOOL;
		WorkPanelName : STRING[255];
		PowerOn : BOOL; (*CNC axes powered*)
		IsHomed : BOOL; (*CNC axes homed - FALSE after every power-up until HOME / INIT*)
		ProgramActive : BOOL; (*CNC program executing (also while interrupted)*)
		ProgramInterrupted : BOOL; (*CNC program interrupted by HALT*)
		Error : BOOL; (*MpCnc3Axis error*)
		StatusID : DINT; (*MpCnc3Axis StatusID*)
		Rejected : E_CNC_ACTION; (*last mailbox command discarded because its preconditions were not met, IDLE after an accepted command*)
		EmergencyStop : BOOL; (*E-stop latched - release the button, then RESET*)
	END_STRUCT;
	E_CNC_ACTION :
		(
		E_ACT_IDLE := 0,
		E_ACT_INIT := 1,
		E_ACT_START := 2,
		E_ACT_HALT := 3,
		E_ACT_STOP := 4,
		E_ACT_RESET := 5,
		E_ACT_CONTINUE := 6,
		E_ACT_LOADPROGRAM := 7,
		E_ACT_HOME := 8,
		E_ACT_ABORT := 10, (*leave the running command without an action (Main), refused while idle*)
		E_ACT_POWER_OFF := 13, (*servo off*)
		E_ACT_MOVE_BLOCK := 14, (*execute Parameter.sBlock (MDI)*)
		E_ACT_START_AT_LINE := 15, (*START from the file line gCncRun.Input.StartLine*)
		E_ACT_MEASURE_Z := 16 (*Z reference measurement with the touch sensor (gZRef) - manual mode, homed*)
		);
END_TYPE

(*Dispenser*)

TYPE
	Dispenser_Type : 	STRUCT 
		Input : DispenserInput_Type;
		Output : DispenserOutput_Type;
	END_STRUCT;
	DispenserInput_Type : 	STRUCT 
		Command : DispenserInputCommand_Type;
		Parameter : DispenserInputParameter_Type;
	END_STRUCT;
	DispenserOutput_Type : 	STRUCT 
		State : DispenserOutputState_Type;
	END_STRUCT;
	DispenserInputCommand_Type : 	STRUCT 
		Discharge : BOOL; (*auto : M41 on / M42 off, driven by Main*)
		Manual : BOOL; (*manual on/off*)
	END_STRUCT;
	DispenserInputParameter_Type : 	STRUCT 
		DischargeDelay : BOOL; (*M44 on / M45 off - flag for the program, no output function on this machine*)
	END_STRUCT;
	DispenserOutputState_Type : 	STRUCT 
		Discharge : BOOL; (*TRUE while the dispenser discharges (DO_Dispenser_Start)*)
	END_STRUCT;
END_TYPE

(*Laser*)

TYPE
	Laser_Type : 	STRUCT 
		Input : LaserInput_Type;
		Output : LaserOutput_Type;
	END_STRUCT;
	LaserInput_Type : 	STRUCT 
		Command : LaserInputCommand_Type;
		Parameter : LaserInputParameter_Type;
	END_STRUCT;
	LaserOutput_Type : 	STRUCT 
		State : LaserOutputState_Type;
	END_STRUCT;
	LaserInputCommand_Type : 	STRUCT 
		Emission : BOOL; (*auto : M61 on / M62 off, driven by Main*)
		Manual : BOOL; (*manual on/off*)
	END_STRUCT;
	LaserInputParameter_Type : 	STRUCT (*written by the HMI (gLaser is not RETAIN, the Laser Init sets the start values)*)
		Power : REAL; (*auto power [%] while the program sets no LaserPower (C_LaserPower < 0)*)
		ManualPower : REAL; (*manual test power [%]*)
		DutyMin : REAL; (*PWM duty for a power just above 0 % [%] - lasing threshold of the driver*)
		DutyMax : REAL; (*PWM duty for 100 % power [%]*)
		PwmPeriod : UINT; (*PWM period [us], 1000..65535 (1000 = 1 kHz, the X20DO4332-1 maximum)*)
		SpeedScale : BOOL; (*corner compensation : power x actual / programmed path velocity*)
		MinSpeedRatio : REAL; (*lower limit of that velocity ratio [%]*)
	END_STRUCT;
	LaserOutputState_Type : 	STRUCT 
		Emission : BOOL; (*TRUE while the laser emits (DO_Laser_On : on and power > 0)*)
		Power : REAL; (*power output now [%], after corner compensation, 0 while off*)
		Duty : REAL; (*PWM duty output now [%]*)
	END_STRUCT;
END_TYPE

(*Axis*)

TYPE
	AXIS_COMMAND : 
		(
		Axis_IDLE := 0,
		Axis_MOVE_ABSOLUTE := 1,
		Axis_STOP := 2,
		Axis_HALT := 3,
		Axis_JOG_NEGATIVE := 4,
		Axis_JOG_POSITIVE := 5,
		Axis_RESET := 6,
		Axis_MOVE_ADDITIVE := 7,
		Axis_HOME := 8,
		Axis_POWER := 9,
		Axis_MOVE_VELOCITY := 10
		);
	AxesInterface_Type : 	STRUCT 
		Input : AxisInput_Type;
		Output : AxisOutput_Type;
	END_STRUCT;
	AxisInput_Type : 	STRUCT 
		Parameter : AxisParameter_Type;
		Command : AxisCommand_Type;
	END_STRUCT;
	AxisOutput_Type : 	STRUCT 
		State : AxisState_Type;
	END_STRUCT;
	AxisCommand_Type : 	STRUCT 
		JogNegative : BOOL;
		JogPositive : BOOL;
		Reset : BOOL;
		Command : AXIS_COMMAND;
	END_STRUCT;
	AxisParameter_Type : 	STRUCT 
		Speed : REAL;
		Position : REAL;
		Distance : REAL;
		JogSpeed : REAL;
		SoftwareLimitsPos : DINT;
		SoftwareLimitsNeg : DINT;
		Power : BOOL; (*target of Axis_POWER : TRUE = on, FALSE = off*)
	END_STRUCT;
	AxisState_Type : 	STRUCT 
		Enable : BOOL;
		Home : BOOL;
		JogNegative : BOOL;
		JogPositive : BOOL;
		Error : BOOL;
		ErrorID : UDINT;
		Status : SINT; (*0: Not Init , 1 : Idle or OK , 2 : Run, 3 : Error *)
		Command : AXIS_COMMAND;
		Position : LREAL;
		Speed : LREAL;
	END_STRUCT;
END_TYPE

(*Drive diagnosis - read-only copies for the HMI, not RETAIN (gAxis is RETAIN and keeps its structure). Written by AxisManual*)

TYPE
	DriveDiag_Type : 	STRUCT
		Valid : BOOL; (*the values below are up to date (MC_ReadAxisInfo.Valid) - FALSE = do not judge them*)
		CommReady : BOOL; (*drive has a network connection (MC_ReadAxisInfo.CommunicationReady) - follows the 'Module ok' status input of the axis config (Config_5), not used yet*)
		ReadyForPowerOn : BOOL; (*drive can be switched on (MC_ReadAxisInfo.ReadyForPowerOn)*)
		Warning : BOOL; (*a warning is active on the drive (MC_ReadAxisInfo.AxisWarning, DS402 status word bit 7)*)
		WarningAlarm : BOOL; (*warning-level alarm for the HMI (alarms.json exType 1) : Warning while Valid and CommReady for 0.5 s, held 2 s after it clears (one alarm per event, no flicker). Display only - the PLC does not react to it*)
	END_STRUCT;
END_TYPE

(*Position move result*)

TYPE
	ManualMoveResult_Type : 	STRUCT (*result of gEquipment.Input.Command.ManualMove, written by AxisManual - its own non-RETAIN global so the RETAIN gEquipment keeps its layout*)
		Result : USINT; (*result of request number Count : 0 none since power-up, 1 running, 2 arrived (every step of the sequence done), 3 refused (dropped, nothing moved), 4 ended before the target (Reason)*)
		Reason : USINT; (*why refused / ended, 0 none : 1 E-stop, 2 auto mode, 3 handwheel selected, 4 CNC command running, 5 axes moving, 6 not homed, 7 servo off, 8 axis error, 9 axis HALT / STOP, 10 an axis move of the sequence was aborted or failed (the sequence went on)*)
		Count : UINT; (*+1 for every ManualMove request the PLC takes (accepted or refused) : a new result also when it equals the last one*)
	END_STRUCT;
END_TYPE

(*Z reference measurement - touch sensor DI_ZRef_Sensor (not wired yet), cycle in Main Action_ZRef.st (CncCommand E_ACT_MEASURE_Z)*)

TYPE
	ZRef_Type : 	STRUCT
		Input : ZRefInput_Type;
		Output : ZRefOutput_Type;
	END_STRUCT;
	ZRefInput_Type : 	STRUCT (*written by the HMI, kept over power off (gZRef is RETAIN) - machine coordinates [mm], Z+ down (0 = top). All 0 = not set : the command is refused*)
		SensorX : LREAL; (*X of the sensor*)
		SensorY : LREAL; (*Y of the sensor*)
		StartZ : LREAL; (*Z above the sensor where the slow search starts*)
		MaxZ : LREAL; (*deepest Z of the search : no signal down to here = failed (at most 50 mm below StartZ)*)
		SafeZ : LREAL; (*Z of the moves to and from the sensor (not below StartZ), usually 0*)
		ProbeVel : REAL; (*search velocity [mm/s], 0 = 2, at most 10. The result is read once per cycle : error up to about ProbeVel x 2 cycles (2 ms) + the input filter*)
		Head : USINT; (*head being measured (HMI head number), copied to Output.Head with the result*)
	END_STRUCT;
	ZRefOutput_Type : 	STRUCT
		ParamOk : BOOL; (*Input valid : SafeZ <= StartZ < MaxZ, search <= 50 mm, all inside the software limits, ProbeVel <= 10*)
		Sensor : BOOL; (*DI_ZRef_Sensor now*)
		Busy : BOOL; (*measurement running*)
		Step : USINT; (*diagnosis: 10 Z to SafeZ, 20 X / Y to the sensor, 30 Z to StartZ, 40 search, 50 braking, 60 Z back to SafeZ*)
		Done : BOOL; (*MeasuredZ is the result of the last measurement (cleared when the next one starts)*)
		MeasuredZ : LREAL; (*Z at the sensor signal [mm, machine]*)
		Head : USINT; (*head of MeasuredZ*)
		ErrorId : USINT; (*last measurement: 0 none, 1 Input not valid, 2 sensor already on at StartZ, 3 no signal down to MaxZ, 4 axis move failed or aborted (jog, axis error), 5 left (STOP, ABORT, E-stop, handwheel), 6 a move did not finish in time*)
	END_STRUCT;
END_TYPE

(*Work offsets G54..G57 - program origin in machine coordinates, set as the standard frame SCS1 before a program / MDI run (Main Action_WorkOffset.st)*)

TYPE
	WorkOffset_Type : 	STRUCT
		Input : WorkOffsetInput_Type;
		Output : WorkOffsetOutput_Type;
	END_STRUCT;
	WorkOffsetInput_Type : 	STRUCT
		Command : WorkOffsetInputCommand_Type;
		Parameter : WorkOffsetInputParameter_Type;
	END_STRUCT;
	WorkOffsetInputCommand_Type : 	STRUCT
		Apply : BOOL; (*pulse: take Parameter over (table and Active), cleared by the PLC - refused while a command / program runs*)
	END_STRUCT;
	WorkOffsetInputParameter_Type : 	STRUCT
		Offset : ARRAY[0..3]OF WorkOffsetXYZ_Type; (*0 = G54 .. 3 = G57 : machine position of the program origin [mm]*)
		Active : USINT; (*0..3 = G54..G57 : offset used by every program and MDI run*)
	END_STRUCT;
	WorkOffsetXYZ_Type : 	STRUCT
		X : LREAL;
		Y : LREAL;
		Z : LREAL;
	END_STRUCT;
	WorkOffsetOutput_Type : 	STRUCT
		Offset : ARRAY[0..3]OF WorkOffsetXYZ_Type; (*table in effect (taken over by Apply, kept over power off)*)
		Active : USINT; (*offset in effect, 0 = G54*)
		InUse : BOOL; (*the frame is set before every run : the active offset or the frame set last is not 0*)
		Rejected : BOOL; (*the last Apply was refused : CNC busy, Active > 3 or a value out of range (10000 mm)*)
		Error : BOOL; (*setting the frame failed - that run was not started*)
		ErrorID : DINT; (*ErrorID of MC_BR_SetStandardFrame, 0 = none*)
	END_STRUCT;
END_TYPE

(*Head (tool) offsets - offset of the mounted head from the reference head tip, set as the standard frame SCS2 before a program / MDI run (Main Action_HeadOffset.st)*)

TYPE
	HeadOffset_Type : 	STRUCT
		Input : HeadOffsetInput_Type;
		Output : HeadOffsetOutput_Type;
	END_STRUCT;
	HeadOffsetInput_Type : 	STRUCT
		Command : HeadOffsetInputCommand_Type;
		Parameter : HeadOffsetInputParameter_Type;
	END_STRUCT;
	HeadOffsetInputCommand_Type : 	STRUCT
		Apply : BOOL; (*pulse: take Parameter over (table and ActiveHead), cleared by the PLC - refused while a command / program runs*)
	END_STRUCT;
	HeadOffsetInputParameter_Type : 	STRUCT
		Offset : ARRAY[1..4]OF HeadOffsetXYZ_Type; (*head 1..4 (HMI head table H1..H4 = plugin PlcId : 1 dispenser, 2 laser) : from the reference head tip (the point the axis positions refer to) to the working point of that head [mm], machine directions (Z+ down)*)
		ActiveHead : USINT; (*mounted head 1..4 whose offset every program and MDI run uses, 0 = none (no offset)*)
	END_STRUCT;
	HeadOffsetXYZ_Type : 	STRUCT
		X : LREAL;
		Y : LREAL;
		Z : LREAL;
	END_STRUCT;
	HeadOffsetOutput_Type : 	STRUCT
		Offset : ARRAY[1..4]OF HeadOffsetXYZ_Type; (*table in effect (taken over by Apply, kept over power off)*)
		ActiveHead : USINT; (*head in effect, 0 = none*)
		InUse : BOOL; (*the frame is set before every run : the active head's offset or the frame set last is not 0*)
		Rejected : BOOL; (*the last Apply was refused : CNC busy, ActiveHead > 4 or a value out of range (1000 mm)*)
		Error : BOOL; (*setting the frame failed - that run was not started*)
		ErrorID : DINT; (*ErrorID of MC_BR_SetStandardFrame, 0 = none*)
	END_STRUCT;
END_TYPE

(*CNC program run options from the HMI (gCncRun, not RETAIN : everything is off after a power-up)*)

TYPE
	CncRun_Type : 	STRUCT
		Input : CncRunInput_Type;
		Output : CncRunOutput_Type;
	END_STRUCT;
	CncRunInput_Type : 	STRUCT
		SingleStep : BOOL; (*TRUE = single step : the program stops after every block, CONTINUE runs the next one (MpCnc3Axis.SingleStep). Not used for MDI*)
		OptionalStop : BOOL; (*TRUE = the program stops at M01, CONTINUE goes on (MC_BR_OptionalStop)*)
		StartLine : UDINT; (*E_ACT_START_AT_LINE : line of the program file to start at, 1 = first line (as C_CurrentLine). Write it before CncCommand 15*)
		ReposVelocityFactor : REAL; (*E_ACT_START_AT_LINE : AxisVelocityFactor of the automatic repositioning to the start point (mcPRGRP_SINGLE_AXIS_AUTOMATIC), Main Init sets 0.1*)
	END_STRUCT;
	CncRunOutput_Type : 	STRUCT
		SingleStepActive : BOOL; (*single step mode active (MpCnc3Axis.SingleStepActive)*)
		OptionalStopActive : BOOL; (*the program stands at M01 (MC_BR_OptionalStop.Interrupting) - CONTINUE goes on*)
		OptionalStopErrorId : DINT; (*ErrorID of MC_BR_OptionalStop, 0 = none - switch OptionalStop off and on again to retry*)
		InterruptStatus : McPrgInfoInterruptEnum; (*why the program is interrupted (MpCnc3Axis Info.Program.InterruptStatus) - for commissioning*)
		ProgramPhase : McPrgPhaseEnum; (*MpCnc3Axis Info.Program.ProgramPhase : start at line = simulation up to the line, repositioning, waiting for CONTINUE, real run*)
	END_STRUCT;
END_TYPE
