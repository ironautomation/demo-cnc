
PROGRAM _CYCLIC

	CASE step OF
		0: (* link the network share as the file device of the CNC programs *)
			fbDevLink.enable := TRUE;
			fbDevLink.pDevice := ADR(deviceName);
			fbDevLink.pParam := ADR(shareParam);
			fbDevLink();

			IF fbDevLink.status = ERR_OK THEN
				linked := TRUE;
				linkStatus := 0;
				step := 10;
			ELSIF fbDevLink.status <> ERR_FUB_BUSY AND fbDevLink.status <> ERR_FUB_ENABLE_FALSE THEN
				linkStatus := fbDevLink.status;
				sysError := FileIoGetSysError();
				fbDevLink.enable := FALSE;
				fbDevLink();
				step := 20;
			END_IF

		10: (* linked *)

		20: (* failed : try again after 10 s (share or PC not reachable yet) *)
			retryTimer(IN := TRUE, PT := T#10s);
			IF retryTimer.Q THEN
				retryTimer(IN := FALSE);
				step := 0;
			END_IF

	END_CASE

END_PROGRAM
