
PROGRAM _INIT
	
	gEquipment.Output.Status.MoveComplete := TRUE;
	
	FOR i := 0 TO AX_LAST DO
		gAxis[i].Input.Parameter.JogSpeed := 50;
	END_FOR;
	
	(* static axis references : index 0 = X, 1 = Y, 2 = Z *)
	fbAxisInfo[AX_X].Axis := ADR(gAxis_X);
	fbAxisInfo[AX_Y].Axis := ADR(gAxis_Y);
	fbAxisInfo[AX_Z].Axis := ADR(gAxis_Z);
	
	fbAxisStatus[AX_X].Axis := ADR(gAxis_X);
	fbAxisStatus[AX_Y].Axis := ADR(gAxis_Y);
	fbAxisStatus[AX_Z].Axis := ADR(gAxis_Z);
	
	fbAxisPosition[AX_X].Axis := ADR(gAxis_X);
	fbAxisPosition[AX_Y].Axis := ADR(gAxis_Y);
	fbAxisPosition[AX_Z].Axis := ADR(gAxis_Z);
	
	fbAxisVelocity[AX_X].Axis := ADR(gAxis_X);
	fbAxisVelocity[AX_Y].Axis := ADR(gAxis_Y);
	fbAxisVelocity[AX_Z].Axis := ADR(gAxis_Z);
	
	fbAxisTorque[AX_X].Axis := ADR(gAxis_X);
	fbAxisTorque[AX_Y].Axis := ADR(gAxis_Y);
	fbAxisTorque[AX_Z].Axis := ADR(gAxis_Z);
	
	fbMoveAbs[AX_X].Axis := ADR(gAxis_X);
	fbMoveAbs[AX_Y].Axis := ADR(gAxis_Y);
	fbMoveAbs[AX_Z].Axis := ADR(gAxis_Z);
	
	fbMoveAdd[AX_X].Axis := ADR(gAxis_X);
	fbMoveAdd[AX_Y].Axis := ADR(gAxis_Y);
	fbMoveAdd[AX_Z].Axis := ADR(gAxis_Z);
	
	fbJog[AX_X].Axis := ADR(gAxis_X);
	fbJog[AX_Y].Axis := ADR(gAxis_Y);
	fbJog[AX_Z].Axis := ADR(gAxis_Z);
	
	fbStop[AX_X].Axis := ADR(gAxis_X);
	fbStop[AX_Y].Axis := ADR(gAxis_Y);
	fbStop[AX_Z].Axis := ADR(gAxis_Z);
	
	fbHalt[AX_X].Axis := ADR(gAxis_X);
	fbHalt[AX_Y].Axis := ADR(gAxis_Y);
	fbHalt[AX_Z].Axis := ADR(gAxis_Z);
	
	fbReset[AX_X].Axis := ADR(gAxis_X);
	fbReset[AX_Y].Axis := ADR(gAxis_Y);
	fbReset[AX_Z].Axis := ADR(gAxis_Z);
	
	fbAxisError[AX_X].Axis := ADR(gAxis_X);
	fbAxisError[AX_Y].Axis := ADR(gAxis_Y);
	fbAxisError[AX_Z].Axis := ADR(gAxis_Z);
	
	fbPower[AX_X].Axis := ADR(gAxis_X);
	fbPower[AX_Y].Axis := ADR(gAxis_Y);
	fbPower[AX_Z].Axis := ADR(gAxis_Z);
	
	fbHome[AX_X].Axis := ADR(gAxis_X);
	fbHome[AX_Y].Axis := ADR(gAxis_Y);
	fbHome[AX_Z].Axis := ADR(gAxis_Z);
	
	FOR i := 0 TO AX_LAST DO
		fbAxisInfo[i].Enable := TRUE;
		fbAxisStatus[i].Enable := TRUE;
		fbAxisPosition[i].Enable := TRUE;
		fbAxisVelocity[i].Enable := TRUE;
		fbAxisTorque[i].Enable := TRUE;
		fbAxisError[i].Enable := TRUE;
		
		fbJog[i].Acceleration := DEFAULT_ACC;
		fbJog[i].Deceleration := DEFAULT_DEC;
		fbMoveAbs[i].Acceleration := DEFAULT_ACC;
		fbMoveAbs[i].Deceleration := DEFAULT_DEC;
		fbMoveAdd[i].Acceleration := DEFAULT_ACC;
		fbMoveAdd[i].Deceleration := DEFAULT_DEC;
		fbStop[i].Deceleration := DEFAULT_DEC;
		fbHalt[i].Deceleration := DEFAULT_DEC;
	END_FOR
	
END_PROGRAM
