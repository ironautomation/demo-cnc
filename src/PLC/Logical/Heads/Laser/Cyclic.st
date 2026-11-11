
PROGRAM _CYCLIC
	
	autoOn(CLK := gEquipment.Output.Status.Mode);
	autoOff(CLK := gEquipment.Output.Status.Mode);
	
	IF autoOn.Q OR autoOff.Q THEN
		gLaser.Input.Command.Manual := FALSE;
	END_IF
	
	(* laser allowed : not in dry run or E-stop *)
	supplyOn := NOT (gEquipment.Input.Parameter.DryRun OR gEquipment.Output.Status.EmergencyStop);
	
	(* emission : level controlled - auto : M61 / M62 (Emission is driven by Main), manual : Command.Manual *)
	IF gEquipment.Output.Status.Mode THEN
		emissionOn := gLaser.Input.Command.Emission;
	ELSE
		emissionOn := gLaser.Input.Command.Manual;
	END_IF
	emissionOn := emissionOn AND supplyOn;
	
	(* X20DO8331 DO02 (on/off laser output) is held off : the PWM laser on X20DO4332-1 is switched on and off by its duty below *)
	DO_Laser_Power := FALSE;
	
	(* power [%] : manual test power, else LaserPower of the program, else the auto power *)
	IF NOT gEquipment.Output.Status.Mode THEN
		power := gLaser.Input.Parameter.ManualPower;
	ELSIF C_LaserPower >= 0.0 THEN
		power := C_LaserPower;
	ELSE
		power := gLaser.Input.Parameter.Power;
	END_IF
	
	(* corner compensation : power x actual / programmed path velocity, so a slower path (corners, feed override) does not burn deeper *)
	fbPathInfo.Enable := gLaser.Input.Parameter.SpeedScale AND gEquipment.Output.Status.ProgramActive;
	fbPathInfo();
	speedRatio := 1.0;
	IF fbPathInfo.Valid AND gEquipment.Output.Status.Mode AND fbPathInfo.PathInfo.ProgrammedPathVelocity > 0.0 THEN
		speedRatio := LIMIT(LIMIT(0.0, gLaser.Input.Parameter.MinSpeedRatio, 100.0) / 100.0,
			fbPathInfo.PathInfo.CurrentPathVelocity / fbPathInfo.PathInfo.ProgrammedPathVelocity, 1.0);
	END_IF
	power := LIMIT(0.0, power * speedRatio, 100.0);
	
	(* PWM : power 0..100 % -> duty DutyMin..DutyMax, duty 0 while off or at power 0 *)
	IF emissionOn AND power > 0.0 THEN
		duty := LIMIT(0.0, gLaser.Input.Parameter.DutyMin + (gLaser.Input.Parameter.DutyMax - gLaser.Input.Parameter.DutyMin) * power / 100.0, 100.0);
	ELSE
		duty := 0.0;
		power := 0.0;
	END_IF
	
	PWM_Laser_Duty := REAL_TO_INT(duty * 327.67);
	PWM_Laser_Period := MAX(gLaser.Input.Parameter.PwmPeriod, 1000); (* 0 would switch PWM off in the module, below 1000 us is not allowed *)
	DO_Laser_On := emissionOn AND PWM_Laser_Duty > 0;
	
	gLaser.Output.State.Emission := DO_Laser_On;
	gLaser.Output.State.Power := power;
	gLaser.Output.State.Duty := duty;
	
END_PROGRAM
