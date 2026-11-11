
(* Nozzle Valve Open *)
ACTION act_M41: (* Asynchronous *)
	
	IF fbMFunction[0].Value = TRUE AND headDispOk THEN (* another head active : refused in act_HeadCheck *)
		gDispenser.Input.Command.Discharge := TRUE;
		fbMFunction[1].Reset := TRUE; (* on/off pair : M41 clears the latched M42 and M42 clears M41, so the last one holds *)
	ELSE
		fbMFunction[1].Reset := FALSE;
	END_IF
	
END_ACTION

(* Nozzle Valve Close - also while no program runs / E-stop (mfClear), so M41 does not stay on *)
ACTION act_M42: (* Asynchronous *)
	
	IF fbMFunction[1].Value = TRUE OR mfClear THEN
		gDispenser.Input.Command.Discharge := FALSE;
		fbMFunction[0].Reset := TRUE;
	ELSE
		fbMFunction[0].Reset := FALSE;
	END_IF
	
END_ACTION

(* Valve Delay On *)
ACTION act_M44: (* Asynchronous *)
	
	IF fbMFunction[2].Value = TRUE THEN
		gDispenser.Input.Parameter.DischargeDelay := TRUE;
		fbMFunction[2].Reset := TRUE;
	ELSE
		fbMFunction[2].Reset := FALSE;
	END_IF
	
END_ACTION

(* Valve Delay Off *)
ACTION act_M45: (* Asynchronous *)
	
	IF fbMFunction[3].Value = TRUE THEN
		gDispenser.Input.Parameter.DischargeDelay := FALSE;
		fbMFunction[3].Reset := TRUE;
	ELSE
		fbMFunction[3].Reset := FALSE;
	END_IF
	
END_ACTION

(* M50..M59 (blocking, range 50..59 of the axes group M-function feature) : no function on this machine. Without a handler the path
   would wait at such a line for ever - reset at once, the program goes on as if the line were not there.
   fbMFunction[6] / [7] watch M50 / M51, fbMFunctionSpare[0..7] M52..M59 *)
ACTION act_MSpare: (* Synchronous *)

	FOR i := 6 TO 7 DO
		IF fbMFunction[i].Value = TRUE THEN
			fbMFunction[i].Reset := TRUE;
			mfSpareLast := 44 + i;
		ELSE
			fbMFunction[i].Reset := FALSE;
		END_IF
	END_FOR

	FOR i := 0 TO 7 DO
		IF fbMFunctionSpare[i].Value = TRUE THEN
			fbMFunctionSpare[i].Reset := TRUE;
			mfSpareLast := 52 + i;
		ELSE
			fbMFunctionSpare[i].Reset := FALSE;
		END_IF
	END_FOR

END_ACTION

(* Laser On *)
ACTION act_M61: (* Asynchronous *)
	
	IF fbMFunction[4].Value = TRUE AND headLaserOk THEN (* another head active : refused in act_HeadCheck *)
		gLaser.Input.Command.Emission := TRUE;
		fbMFunction[5].Reset := TRUE; (* on/off pair, as M41 / M42 *)
	ELSE
		fbMFunction[5].Reset := FALSE;
	END_IF
	
END_ACTION

(* Laser Off - also while no program runs / E-stop (mfClear), so M61 does not stay on *)
ACTION act_M62: (* Asynchronous *)
	
	IF fbMFunction[5].Value = TRUE OR mfClear THEN
		gLaser.Input.Command.Emission := FALSE;
		fbMFunction[4].Reset := TRUE;
	ELSE
		fbMFunction[4].Reset := FALSE;
	END_IF
	
END_ACTION
