
PROGRAM _INIT

	axisRef[AX_X] := ADR(gAxis_X);
	axisRef[AX_Y] := ADR(gAxis_Y);
	axisRef[AX_Z] := ADR(gAxis_Z);

	FOR i := 0 TO AX_LAST DO
		fbMpgMove[i].Axis := axisRef[i];
		fbMpgStop[i].Axis := axisRef[i];
		fbMpgPosition[i].Axis := axisRef[i];
		fbMpgStatus[i].Axis := axisRef[i];
		fbMpgPosition[i].Enable := TRUE;
		fbMpgStatus[i].Enable := TRUE;
		fbMpgMove[i].Acceleration := MPG_ACC;
		fbMpgMove[i].Deceleration := MPG_ACC;
		fbMpgStop[i].Deceleration := MPG_ACC;
	END_FOR

END_PROGRAM
