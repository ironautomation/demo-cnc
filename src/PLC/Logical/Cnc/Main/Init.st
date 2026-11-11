
PROGRAM _INIT
	
	gEquipment.Input.CncCommand := E_ACT_IDLE;

	gEquipment.Output.State.Initialized := FALSE;
	gEquipment.Input.Parameter.SystemSpeed := 200; (* [mm/s] position move speed - axis velocity limit is 200 (mappMotion Config_2) *)
	gEquipment.Input.Parameter.Feedrate := 100;

	(* mapp Motion CNC : static references *)
	fbCnc.MpLink := ADR(gCncXYZ);
	fbCnc.Parameters := ADR(CncParameters);
	fbCnc.Enable := TRUE;
	fbCnc.Override := 100.0;
	fbCnc.RapidOverride := 100.0;
	fbCnc.FeedrateOverride := 100.0;
	
	(* Jog path limits : adjust to machine limits *)
	CncParameters.Jog.PathLimits.Velocity := 1000.0;			(* [mm/s] *)
	CncParameters.Jog.PathLimits.Acceleration := 5000.0;		(* [mm/s^2] *)
	CncParameters.Jog.PathLimits.Deceleration := 5000.0;		(* [mm/s^2] *)
	
	(* M-Functions : async (AxesGroup M-function feature, ranges 40..49 / 60..69 non-blocking), M50 / M51 blocking (50..59, no function) *)
	fbMFunction[0].MFunction := 41;
	fbMFunction[1].MFunction := 42;
	fbMFunction[2].MFunction := 44;
	fbMFunction[3].MFunction := 45;
	fbMFunction[4].MFunction := 61;
	fbMFunction[5].MFunction := 62;
	fbMFunction[6].MFunction := 50;
	fbMFunction[7].MFunction := 51;
	FOR i := 0 TO 7 DO
		fbMFunction[i].AxesGroup := ADR(gCncXYZ);
		fbMFunction[i].Enable := TRUE;
	END_FOR
	(* M52..M59 : no function here too, act_MSpare lets the path go on (blocking codes of the range would wait for ever) *)
	FOR i := 0 TO 7 DO
		fbMFunctionSpare[i].MFunction := USINT_TO_UDINT(52 + i);
		fbMFunctionSpare[i].AxesGroup := ADR(gCncXYZ);
		fbMFunctionSpare[i].Enable := TRUE;
	END_FOR
	
	(* Optional stop (M01) : enabled from the HMI (gCncRun.Input.OptionalStop) in Cyclic *)
	fbOptStop.AxesGroup := ADR(gCncXYZ);
	(* Start at line : velocity factor of the automatic single-axis repositioning to the start point - slow on purpose, check on site *)
	gCncRun.Input.ReposVelocityFactor := 0.1;
	

	(* Z reference measurement (act_MeasureZ) : own single-axis FBs. gZRef.Input (RETAIN) is kept *)
	fbZrMove[0].Axis := ADR(gAxis_X);
	fbZrMove[1].Axis := ADR(gAxis_Y);
	fbZrMove[2].Axis := ADR(gAxis_Z);
	fbZrHalt[0].Axis := ADR(gAxis_X);
	fbZrHalt[1].Axis := ADR(gAxis_Y);
	fbZrHalt[2].Axis := ADR(gAxis_Z);
	FOR i := 0 TO 2 DO
		fbZrMove[i].Acceleration := C_ZREF_ACC;
		fbZrMove[i].Deceleration := C_ZREF_ACC;
		fbZrHalt[i].Deceleration := C_ZREF_ACC;
	END_FOR
	gZRef.Output.Busy := FALSE;
	gZRef.Output.Step := 0;
	
	(* Work offsets G54..G57 : the active one is set as standard frame SCS1 before a run (act_WorkOffset).
	   The table (gWorkOffset, RETAIN) is kept; the axes group starts with frame 0, so woSet starts at 0 *)
	fbWorkFrame.AxesGroup := ADR(gCncXYZ);
	fbWorkFrame.CoordSystem := mcSCS1;
	fbWorkFrame.ExecutionMode := mcEM_IMMEDIATELY;
	gWorkOffset.Input.Command.Apply := FALSE;
	gWorkOffset.Output.Rejected := FALSE;
	gWorkOffset.Output.Error := FALSE;
	gWorkOffset.Output.ErrorID := 0;
	
	(* Head (tool) offsets : minus the mounted head's offset is set as standard frame SCS2 before a run (act_HeadOffset).
	   The table (gHeadOffset, RETAIN) is kept; the axes group starts with frame 0, so hoSet starts at 0 *)
	fbHeadFrame.AxesGroup := ADR(gCncXYZ);
	fbHeadFrame.CoordSystem := mcSCS2;
	fbHeadFrame.ExecutionMode := mcEM_IMMEDIATELY;
	gHeadOffset.Input.Command.Apply := FALSE;
	gHeadOffset.Output.Rejected := FALSE;
	gHeadOffset.Output.Error := FALSE;
	gHeadOffset.Output.ErrorID := 0;
	
	(* Axis reset FBs *)
	fbAxisReset[0].Axis := ADR(gAxis_X);
	fbAxisReset[1].Axis := ADR(gAxis_Y);
	fbAxisReset[2].Axis := ADR(gAxis_Z);
	
	(* X axis mechanical deviation compensation
	   NOTE: comp table (Position/Deviation pairs) is now defined in the axis feature
	   configuration (mcCFG_AX_FEAT_MECH_DEV_COMP) instead of runtime arrays.
	   Legacy values [mm]: P = 0 / 1000 / 2000 / 3100, D = 0 / Deviation_X1 / X2 / X3 *)
	fbMechDevCompX.Axis := ADR(gAxis_X);
	
	(* Teach positions C_TP1_1 .. C_TP4_3 : only CNC programs (Config_4 aliases TP1_1 ..) and the HMI (OPC UA) use them.
	   A global PV that no task references is not created on the target (OPC UA read = BadResourceUnavailable),
	   so they are referenced here once *)
	teachSum := C_TP1_1 + C_TP1_2 + C_TP1_3 + C_TP2_1 + C_TP2_2 + C_TP2_3
	          + C_TP3_1 + C_TP3_2 + C_TP3_3 + C_TP4_1 + C_TP4_2 + C_TP4_3;
	
END_PROGRAM
