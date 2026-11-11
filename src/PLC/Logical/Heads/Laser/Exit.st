

PROGRAM _EXIT
	
	DO_Laser_Power := FALSE;
	DO_Laser_On := FALSE;
	PWM_Laser_Duty := 0;
	
	fbPathInfo.Enable := FALSE;
	fbPathInfo();
	 
END_PROGRAM
