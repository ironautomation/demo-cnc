ACTION act_Jog:
	
	FOR i := 0 TO AX_LAST BY 1 DO
		JogSpeed[i] := gAxis[i].Input.Parameter.JogSpeed;
	END_FOR
	
END_ACTION
