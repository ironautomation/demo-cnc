

PROGRAM _INIT
	
	(* gLaser is not RETAIN : the HMI writes the head table values when they differ from these.
	   Until then the laser stays dark (power 0) - a program can still set LaserPower. *)
	gLaser.Input.Parameter.Power := 0.0;
	gLaser.Input.Parameter.ManualPower := 0.0;
	gLaser.Input.Parameter.DutyMin := 0.0;
	gLaser.Input.Parameter.DutyMax := 100.0;
	gLaser.Input.Parameter.PwmPeriod := 1000; (* 1 kHz *)
	gLaser.Input.Parameter.SpeedScale := FALSE;
	gLaser.Input.Parameter.MinSpeedRatio := 20.0;
	
	fbPathInfo.AxesGroup := ADR(gCncXYZ);
	
	DO_Laser_Power := FALSE;
	DO_Laser_On := FALSE;
	PWM_Laser_Duty := 0;
	
END_PROGRAM
