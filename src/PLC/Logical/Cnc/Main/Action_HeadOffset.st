ACTION act_HeadOffset:
	(* Head (tool) offsets : the axis positions refer to the reference head tip, each head's working point sits at its offset
	   from there (HMI head table, H1..H4 = PlcId). Only one head is mounted at a time (HMI plugin structure), so the offset of
	   the mounted head (ActiveHead) holds for every run. Apply (HMI) takes the table and the mounted head over while the CNC is
	   idle (refused otherwise : Output.Rejected). act_Start / act_MoveBlock set minus that offset as the standard
	   frame SCS2 (MC_BR_SetStandardFrame, translation only) right before the run, so the head's working point follows the
	   program : machine = program - offset.
	   While the mounted head's offset and the frame set last are both 0 (the default, ActiveHead 0 or the reference head)
	   nothing is set. Single-axis moves (jog, ManualMove, teach positions), homing, the ring
	   buffer stay at the reference head tip.
	   mapp tool tables (MC_BR_SetToolTable / MC_BR_SetToolPar) are not used : the axes group has no tool feature configured *)

	(* Apply : only while idle and with sane values - a run in progress keeps its frame *)
	IF gHeadOffset.Input.Command.Apply THEN
		gHeadOffset.Input.Command.Apply := FALSE;
		hoOk := cncCommand = E_ACT_IDLE AND NOT programAlive AND hoStep = 0
			AND gHeadOffset.Input.Parameter.ActiveHead <= 4;
		FOR hoIdx := 1 TO 4 DO
			hoOk := hoOk AND ABS(gHeadOffset.Input.Parameter.Offset[hoIdx].X) <= C_HO_MAX
				AND ABS(gHeadOffset.Input.Parameter.Offset[hoIdx].Y) <= C_HO_MAX
				AND ABS(gHeadOffset.Input.Parameter.Offset[hoIdx].Z) <= C_HO_MAX;
		END_FOR
		IF hoOk THEN
			FOR hoIdx := 1 TO 4 DO
				gHeadOffset.Output.Offset[hoIdx] := gHeadOffset.Input.Parameter.Offset[hoIdx];
			END_FOR
			gHeadOffset.Output.ActiveHead := gHeadOffset.Input.Parameter.ActiveHead;
		END_IF
		gHeadOffset.Output.Rejected := NOT hoOk;
	END_IF

	(* frame of the mounted head : minus its offset (translation only), none = 0 *)
	hoWant.Pos.X := 0.0;
	hoWant.Pos.Y := 0.0;
	hoWant.Pos.Z := 0.0;
	IF gHeadOffset.Output.ActiveHead >= 1 AND gHeadOffset.Output.ActiveHead <= 4 THEN
		hoIdx := gHeadOffset.Output.ActiveHead;
		hoWant.Pos.X := -gHeadOffset.Output.Offset[hoIdx].X;
		hoWant.Pos.Y := -gHeadOffset.Output.Offset[hoIdx].Y;
		hoWant.Pos.Z := -gHeadOffset.Output.Offset[hoIdx].Z;
	END_IF

	(* set before a run only when an offset is or was in use - it is set again before every run, so a frame that mapp
	   Motion resets at the end of a program (modal data) is back for the next one *)
	hoNeed := hoWant.Pos.X <> 0.0 OR hoWant.Pos.Y <> 0.0 OR hoWant.Pos.Z <> 0.0
		OR hoSet.Pos.X <> 0.0 OR hoSet.Pos.Y <> 0.0 OR hoSet.Pos.Z <> 0.0;
	gHeadOffset.Output.InUse := hoNeed;

	(* the run that requested the frame is over (also STOP / ABORT while it was set) *)
	IF (hoStep = 100 OR hoStep = 200) AND cncCommand = E_ACT_IDLE THEN
		hoStep := 0;
	END_IF

	CASE hoStep OF
		1: (* requested by act_Start / act_MoveBlock *)
			hoTimer(IN := FALSE);
			gHeadOffset.Output.Error := FALSE;
			gHeadOffset.Output.ErrorID := 0;
			fbHeadFrame.Frame := hoWant;
			fbHeadFrame.Execute := TRUE;
			hoStep := 10;

		10:
			hoTimer(IN := TRUE, PT := T#2s);

			IF fbHeadFrame.Done THEN
				hoTimer(IN := FALSE);
				fbHeadFrame.Execute := FALSE;
				hoSet := fbHeadFrame.Frame;
				hoStep := 100;
			ELSIF fbHeadFrame.Error OR hoTimer.Q THEN
				(* the run is not started : the head would work at the wrong place *)
				hoTimer(IN := FALSE);
				fbHeadFrame.Execute := FALSE;
				gHeadOffset.Output.Error := TRUE;
				gHeadOffset.Output.ErrorID := fbHeadFrame.ErrorID;
				hoStep := 200;
			END_IF

		100:
			;(* set - the action goes on with the run *)

		200:
			;(* failed - the action ends with 200 *)
	END_CASE

END_ACTION
