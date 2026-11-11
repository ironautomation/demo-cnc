
(* Records axis positions, head on (discharge or laser), moving state, the laser power and the value of the
   active head into a ring buffer. Runs in Cyclic#1 (2ms), same task class as the motion programs. *)
PROGRAM _CYCLIC
	BufferX[Head] := gAxis[AX_X].Output.State.Position;
	BufferY[Head] := gAxis[AX_Y].Output.State.Position;
	BufferZ[Head] := gAxis[AX_Z].Output.State.Position;
	BufferHeadOn[Head] := gDispenser.Input.Command.Discharge OR gLaser.Input.Command.Emission;
	BufferMoving[Head] := gEquipment.Output.State.Move;
	BufferLaserPower[Head] := REAL_TO_USINT(LIMIT(0.0, gLaser.Output.State.Power, 100.0));
	(* value of the active head : the laser power for the laser - also while the head is not known (gActiveHead 0),
	   the laser is the only head with a value - and 0 for a head without a value (dispenser) *)
	IF gActiveHead = 0 OR gActiveHead = HEAD_LASER THEN
		BufferHeadValue[Head] := BufferLaserPower[Head];
	ELSE
		BufferHeadValue[Head] := 0;
	END_IF

	Head := Head + 1;
	IF Head >= RB_SIZE THEN
		Head := 0;
	END_IF
END_PROGRAM
