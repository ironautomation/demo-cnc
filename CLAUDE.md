# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A B&R Automation Studio **6.5** project (`src/PLC/DemoCNC.apj`) for a demo 3-axis Cartesian (X/Y/Z) CNC machine with a dispenser head and a PWM diode laser head. Target is an **X20CP1684** PLC; axes are Yaskawa Σ-X servo drives over EtherCAT (CoE, DS402 CSP) driven through mapp Motion (`MpCnc3Axis`, `McPureVAx`). The language is IEC 61131-3 Structured Text (`.st`) plus B&R declaration files (`.var`, `.typ`, `.fun`).

CLI build: see `docs/build-cli.md` (`BR.AS.Build.exe`). Building, transferring and running can also be done in **Automation Studio** (open `src/PLC/DemoCNC.apj`). `src/PLC/Temp`, `Binaries`, `Diagnosis`, `*.set`, `*.isopen` are gitignored build/per-user output.

## Machine (장비 구성)

- PLC X20CP1684 + X20IF10G1-1 (EtherCAT master) → Yaskawa SGDXT 3-axis servo pack (X, Y, Z; incremental encoders — homing is lost on every power-up).
- X20DI9372 ×2 (axis limit/home sensors, MPG pendant), X20DO8331 (dispenser discharge `DO_Dispenser_Start`), X20DO4332-1 (laser PWM, channel 1), X20DC1176.
- Heads: dispenser (M41/M42 discharge on/off, M44/M45 discharge delay) and PWM laser (M61/M62 emission on/off). One head is mounted at a time.
- No safety PLC in this project. The E-stop handling in `Main` is a software reaction only — the safety circuit is wired separately.

## Folder structure (폴더 구조)

```
src/PLC/                 Automation Studio project (DemoCNC.apj)
  Logical/Global.var|typ global variables and types (the interface between tasks and to the HMI)
  Logical/Cnc            Main (CNC sequencer, M functions, offsets, Z reference), OpMode (auto/manual mode), PrgShare (CNC program share)
  Logical/Motion         AxisManual (manual axis moves), Handwheel (MPG), RingBuffer (HMI trace)
  Logical/Heads          Dispenser, Laser (head outputs)
  Logical/Libraries      vendored B&R libraries - do not edit
  Physical/Config1       hardware, I/O mapping, task layout (Cpu.sw), mapp Motion configs
src/HMI                  IronHMI project (landscape 1920×1080) - the screen used in the videos
gcode/                   test CNC programs
episodes/NN-*/           per-video material (README per episode, examples, samples)
docs/                    build-cli.md
.claude/                 hooks, rules and skills for Claude Code
```

## Architecture

**Task layout** is defined in `src/PLC/Physical/Config1/X20CP1684/Cpu.sw` (not in the `Logical` tree). A program only runs if it is listed there:
- `Cyclic#1` (2 ms): `Cnc/Main`, `Motion/AxisManual`, `Motion/Handwheel`, `Motion/RingBuffer`, `Heads/Dispenser`, `Heads/Laser`, `Cnc/OpMode`
- `Cyclic#4` (slower): `Cnc/PrgShare`

Adding a new program needs both a `Package.pkg` entry under `Logical/` and a task entry in `Cpu.sw`.

**Communication is through global variables** in `Logical/Global.var` / `Global.typ` rather than function calls between programs:
- `gEquipment` (`Equip_Type`, RETAIN) — HMI/system command interface. `Input.CncCommand` is the command mailbox; `Output.Status/State` is reported back to the HMI (`Rejected`, `PowerOn`, `IsHomed`, `ProgramActive`, `ProgramInterrupted`, `Error`, `StatusID`, `EmergencyStop`).
- `gAxis[0..2]` (`AxesInterface_Type`, RETAIN) — per-axis Input (jog/move commands, parameters) and Output (position/state). Indices `AX_X/AX_Y/AX_Z`.
- `gDispenser`, `gLaser` — head commands and parameters. `gCncRun` — single step, M01, start at line.
- Drive adapter PVs `gDS402_X/Y/Z` sit in their own block at the top of `Global.var`. Program logic only uses the mapp references `gAxis_X/Y/Z` and `gCncXYZ`.

**`Main`** (`Logical/Cnc/Main`) is the CNC sequencer. `Cyclic.st` checks each mailbox command (`cmdAllowed`), takes `gEquipment.Input.CncCommand` into the internal `cncCommand` (`E_CNC_ACTION`: IDLE/INIT/HOME/START/HALT/CONTINUE/STOP/RESET/…), then a `CASE` runs the matching action while `commandStep` advances to **100 (done)** or **200 (failed)**, which returns the state to IDLE. A refused command is reported in `gEquipment.Output.Status.Rejected`. Actions (`act_Init`, `act_Home`, `act_Start`, `act_Stop`, …) live in `Action_NC.st`; M-code handlers in `Action_MCode.st` (M50..M59 have no function and are reset at once so a program never waits there).

- START needs power, homing and auto mode (`DI_Auto`); HOME needs power; HALT needs a running program; CONTINUE an interrupted one.
- **Homing order is Z first, then X·Y.** Homing is always an operator command (`INIT` = power + home, or `HOME`).
- `OpMode` sets `DI_Auto := NOT gEquipment.Input.Command.ManualMode` (no selector switch), taken over only while the CNC is idle.
- E-stop: `DI_MPG_Jog_EMS1` (NC contact) latches `emergencyLatched` — CNC STOP, servo off, heads off; RESET clears it once the button is released.

**`Motion/AxisManual`** = manual jog / move-to-position per axis, active only in manual mode, without handwheel, while the CNC is idle. **`Motion/Handwheel`** = handwheel (MPG). **`Motion/RingBuffer`** = axis position, head-on, moving state and laser power per scan for the HMI 3D trace (task name fixed: the prebuilt HMI laser plugin reads `::RingBuffer:BufferLaserPower`).

**Physical config** (`Physical/Config1/X20CP1684`): `Hardware.hw` (modules), `IoMap.iom` (channel → PV mapping), `mappMotion/3AxesCNCXYZ/Config_*` (axes group, axis, mechanical system, features), `DTM/` (Yaskawa drive config). New I/O requires changes in both `Hardware.hw` and `IoMap.iom`.

## HMI

The IronHMI project `src/HMI` (landscape 1920×1080) runs on the IronHMI runtime and talks to the PLC over OPC UA (`project.manifest.json`, default `opc.tcp://127.0.0.1:4840` for ARsim on the same PC; node keys `::AsGlobalPV:<path>` and `::RingBuffer:<var>`). `Controls/*.dll` and `Plugins/*` are prebuilt; `Database/` and `Logs/` are created by the runtime and gitignored. `Models/cnc_gantry.glb` is the 3D twin of the gantry.

## Naming (이름 규칙)

- Axis indexes are the global constants `AX_X/AX_Y/AX_Z`, loops run `FOR i := 0 TO AX_LAST`.
- Globals start with `g` (`gEquipment`, `gAxis`); digital I/O PVs `DI_*` / `DO_*`; CNC program variables (aliases in `Config_4`) `C_*`; constants upper case.
- Commands are the enum `E_CNC_ACTION` (`E_ACT_*`). Step counters end at 100 (done) / 200 (failed).
- Each program folder has `IEC.prg` (file list), `Variables.var`, `Types.typ` (optional), `Init/Cyclic/Exit.st` and extra `Action_*.st` files. Actions are called by name (e.g. `act_Home;`) inside `Cyclic.st`; a new `.st` action file must be registered in that folder's `IEC.prg`.
- A global PV that no task's code references is not created on the target (OPC UA reads `BadResourceUnavailable`). A global used only by the HMI or a G-code alias must be referenced once in a task.
- Source files contain Korean text; keep UTF-8 (the `.apj` has a BOM — preserve it).

## Build and test (빌드·시험 방법)

1. Command line: `docs/build-cli.md` — `BR.AS.Build.exe <absolute path>\src\PLC\DemoCNC.apj -c Config1 -all -t <short temp path>` (a relative `.apj` path only prints the usage text). Expected result: no error in the ST code (`Main` 0 errors). The two remaining mappView/grunt errors are unrelated to ST.
2. Or Automation Studio: open `src/PLC/DemoCNC.apj`, Build (Main 0 errors).
3. Without a machine: run the configuration in ARsim, start `src/HMI` with IronHMI and run `gcode/HOME_RUN_TEST.cnc` (head off) — check the 3D twin.
4. On the machine: check the E-stop first, then HOME, then the test program with the head off.

## Rules (하면 안 되는 것)

- Work on a branch (`feature/`, `fix/`, `hotfix/`, `refactor/`), merge through a Pull Request. **No direct commit or push to `main`** — enforced by `.claude/hooks/git-guard.sh`. Details: `.claude/rules/git-workflow.md`. Commit messages in Korean.
- **Back up before changing** a program (copy the folder, see `episodes/02-ai-plc/home_and_run`), so a change can be rolled back.
- **Do not touch safety-related code**: the E-stop handling (`emergencyLatched`, `DI_MPG_Jog_EMS1`), limit switches, servo power-off paths. The safety circuit and emergency stop are hardware and are designed separately.
- Do not edit vendored libraries under `Logical/Libraries/`.
- Do not change `RETAIN` structures (`gEquipment`, `gAxis`) without asking — their layout is kept on the target.
- Every change must build (Main 0 errors) before it is merged.
- Episode tags (`epNN-*`) are fixed once the video is public — never move or delete them. See `.claude/skills/release-tag/SKILL.md`.
