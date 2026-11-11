(* One head on the machine (HMI plugin structure). Head number HEAD_* = PlcId of the HMI head plugin.
   gActiveHead (written by the HMI) : only the M functions and the manual on of that head are taken. An M function of another head
   stops the running program (like STOP from the HMI : the run ends as stopped, not complete), a manual on of another head is dropped,
   its outputs stay off; gHeadRefused shows that head until the next run starts or RESET.
   gActiveHead = 0 (not written yet after a PLC restart) : no check *)
ACTION act_HeadCheck:

	headDispOk := gActiveHead = 0 OR gActiveHead = HEAD_DISPENSER;
	headLaserOk := gActiveHead = 0 OR gActiveHead = HEAD_LASER;

	(* the last refusal shows until the next run starts or RESET *)
	headRunTrig(CLK := programAlive);
	IF headRunTrig.Q OR cncCommand = E_ACT_RESET THEN
		gHeadRefused := 0;
	END_IF

	(* an on code (M41 / M61) counts by its value - it is held in reset while no program runs (mfClear, act_M42 / act_M62).
	   The off codes (M42 / M62, reset only by the next on code) and the delay flags (M44 / M45, pulses) count on their rising edge,
	   so a value left over from an earlier run of the other head is not taken as new *)
	FOR i := 0 TO 5 DO
		headMfTrig[i](CLK := fbMFunction[i].Value);
	END_FOR

	headRefuse := 0;
	IF NOT headDispOk AND (fbMFunction[0].Value OR headMfTrig[1].Q OR headMfTrig[2].Q OR headMfTrig[3].Q) THEN
		headRefuse := HEAD_DISPENSER;
	END_IF
	IF NOT headLaserOk AND (fbMFunction[4].Value OR headMfTrig[5].Q) THEN
		headRefuse := HEAD_LASER;
	END_IF

	IF headRefuse <> 0 THEN
		gHeadRefused := headRefuse;
		IF programAlive AND cncCommand <> E_ACT_STOP THEN
			cncCommand := E_ACT_STOP;
			commandStep := 0;
		END_IF
	END_IF

	(* a head that is not the active one stays off : act_M41 / act_M61 do not switch it on, its manual on is dropped *)
	IF NOT headDispOk THEN
		IF gDispenser.Input.Command.Manual THEN
			gHeadRefused := HEAD_DISPENSER;
		END_IF
		gDispenser.Input.Command.Discharge := FALSE;
		gDispenser.Input.Command.Manual := FALSE;
	END_IF

	IF NOT headLaserOk THEN
		IF gLaser.Input.Command.Manual THEN
			gHeadRefused := HEAD_LASER;
		END_IF
		gLaser.Input.Command.Emission := FALSE;
		gLaser.Input.Command.Manual := FALSE;
	END_IF

END_ACTION
