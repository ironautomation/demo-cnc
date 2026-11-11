# HMI_Vertical(세로 1080x1920 · 콘텐츠 리전 1080x1720) 구성설정 화면 생성기 — -Out 을 생략하면 src/HMI_Vertical/Screen/Panel/Panel_Config.xaml 에 쓴다
param([string]$Out)
# Panel_Config.xaml 생성기 — 탭 3개: [위치 · 속도] 지정 위치(TeachPositionEditor) · 속도/소프트 리밋(AnalogBox) / [헤드 · 좌표계] 헤드 테이블 · 공작물 영점 / [시스템]
if (-not $Out) { $Out = Join-Path $PSScriptRoot '..\Screen\Panel\Panel_Config.xaml' }
# [IO.File] 은 PowerShell 현재 위치가 아니라 프로세스 현재 디렉터리를 기준으로 상대 경로를 푸니 미리 절대 경로로 바꾼다
$Out = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Out)
$utf8 = New-Object System.Text.UTF8Encoding($false)
$sb = New-Object System.Text.StringBuilder
function L([string]$s) { [void]$sb.AppendLine($s) }
function Box([double]$x, [double]$y, [double]$w, [string]$tag, [int]$dec, [string]$min, [string]$max, [double]$h = 40) {
  $range = ''
  if ($min -ne '') { $range += " Min=""$min""" }
  if ($max -ne '') { $range += " Max=""$max""" }
  L "    <ironControls:AnalogBox Canvas.Left=""$x"" Canvas.Top=""$y"" Width=""$w"" Height=""$h"" Style=""{StaticResource Edit}"" Type=""Output"" KeyPadUse=""True"" ValueTag=""$tag"" DecimalPlace=""$dec""$range />"
}
# 지정 위치 칸 — PLC 태그가 아니라 HMI 파일(Config\TeachPositions.xml)의 한 위치·한 축(CncControls.TeachValueBox, 생김새는 AnalogBox Edit 와 같다)
function TeachBox([double]$x, [double]$y, [double]$w, [string]$key, [string]$axis, [string]$min, [string]$max) {
  L "    <cnc:TeachValueBox Canvas.Left=""$x"" Canvas.Top=""$y"" Width=""$w"" Height=""40"" access:Access.Level=""5"" TeachFile=""Config\TeachPositions.xml"" Key=""$key"" Axis=""$axis"" DecimalPlace=""3"" Min=""$min"" Max=""$max"" />"
}
function Text([double]$x, [double]$y, [string]$style, [string]$text, [string]$extra = '') {
  L "    <TextBlock Canvas.Left=""$x"" Canvas.Top=""$y"" Style=""{StaticResource $style}""$extra Text=""$text"" />"
}

L '<Canvas'
L '    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"'
L '    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"'
L '    xmlns:opc="clr-namespace:IronHMI.OpcUaBridge;assembly=IronHMI.OpcUaBridge"'
L '    xmlns:action="clr-namespace:IronHMI.Actions;assembly=IronHMI.Common"'
L '    xmlns:access="clr-namespace:IronHMI.Controls.Abstractions;assembly=IronHMI.Controls.Abstractions"'
L '    xmlns:ironControls="clr-namespace:IronControls;assembly=IronControls"'
L '    xmlns:cnc="clr-namespace:CncControls;assembly=CncControls"'
L '    Width="1080"'
L '    Height="1720"'
L '    Background="{DynamicResource Surface1}">'
L '    <!-- 구성설정 — 속도·소프트 리밋은 PLC 값을 직접 고치고(값을 누르면 키패드, 입력 즉시 PLC 에 쓰기), 지정 위치는 HMI 파일(Config\TeachPositions.xml)에 쓴다. 이 파일은 생성기로 만들었다:'
L '         왼쪽 네비 3칸 = [위치 · 속도] 지정 위치 · 속도/축 소프트 리밋 · 공작물 영점(PLC 대기) / [플러그인] 헤드 · 배치 · 추가 / [시스템] 장비 이름 · 정보 · 설정 내보내기. 레시피는 2026-10 PLC 개편으로 없다.'
L '         편집 권한 Access.Level 5 — 운전자(10)는 보기만. 확정 전 사용자 확인 필요. -->'
L '    <Canvas.Resources>'
L '        <Style x:Key="Edit" TargetType="ironControls:AnalogBox">'
L '            <Setter Property="opc:OpcUaNode.ConnectionId" Value="cnc-plc" />'
L '            <Setter Property="access:Access.Level" Value="5" />'
L '            <Setter Property="FontFamily" Value="{DynamicResource MonoFont}" />'
L '            <Setter Property="FontSize" Value="16" />'
L '            <Setter Property="Foreground" Value="{DynamicResource Fg1}" />'
L '            <Setter Property="Background" Value="{DynamicResource Bg}" />'
L '            <Setter Property="BorderBrush" Value="{DynamicResource BorderStrong}" />'
L '            <Setter Property="CornerRadius" Value="8" />'
L '        </Style>'
L '        <Style x:Key="PageTitle" TargetType="TextBlock">'
L '            <Setter Property="FontFamily" Value="{DynamicResource UiFont}" />'
L '            <Setter Property="FontSize" Value="22" />'
L '            <Setter Property="FontWeight" Value="Bold" />'
L '            <Setter Property="Foreground" Value="{DynamicResource Fg1}" />'
L '        </Style>'
L '        <Style x:Key="CardTitle" TargetType="TextBlock">'
L '            <Setter Property="FontFamily" Value="{DynamicResource UiFont}" />'
L '            <Setter Property="FontSize" Value="15" />'
L '            <Setter Property="FontWeight" Value="SemiBold" />'
L '            <Setter Property="Foreground" Value="{DynamicResource Fg1}" />'
L '        </Style>'
L '        <Style x:Key="Caption" TargetType="TextBlock">'
L '            <Setter Property="FontFamily" Value="{DynamicResource UiFont}" />'
L '            <Setter Property="FontSize" Value="12" />'
L '            <Setter Property="Foreground" Value="{DynamicResource Fg2}" />'
L '        </Style>'
L '        <Style x:Key="ColHead" TargetType="TextBlock" BasedOn="{StaticResource Caption}">'
L '            <Setter Property="FontWeight" Value="SemiBold" />'
L '            <Setter Property="TextAlignment" Value="Center" />'
L '        </Style>'
L '        <Style x:Key="RowHead" TargetType="TextBlock">'
L '            <Setter Property="FontFamily" Value="{DynamicResource UiFont}" />'
L '            <Setter Property="FontSize" Value="14" />'
L '            <Setter Property="FontWeight" Value="Medium" />'
L '            <Setter Property="Foreground" Value="{DynamicResource Fg1}" />'
L '        </Style>'
L '        <Style x:Key="Card" TargetType="Border">'
L '            <Setter Property="Background" Value="{DynamicResource Bg}" />'
L '            <Setter Property="BorderBrush" Value="{DynamicResource Border}" />'
L '            <Setter Property="BorderThickness" Value="1" />'
L '            <Setter Property="CornerRadius" Value="12" />'
L '        </Style>'
L '    </Canvas.Resources>'
L ''
L '    <cnc:GuiClickLogger ScreenName="Config" LogFolder="Logs\Event" />'
# 플러그인 구조 3 단계: 위쪽 탭 → 왼쪽 세로 네비(24,12 · 168 폭), 콘텐츠는 204 ~ 1056(폭 852)

# ---- 탭 [위치 · 속도] — 지정 위치(이름·개수는 Config\Machine.xml, 값은 TeachPositions.xml) · 속도 · 소프트 리밋 · 공작물 영점 ----
L ''
L '    <!-- ===== 탭 [위치 · 속도] — ConfigTabBar 가 x:Name 으로 보이고 숨긴다. 콘텐츠 204 ~ 1056 ===== -->'
L '    <Canvas x:Name="TabPosition" Canvas.Left="0" Canvas.Top="0" Width="1080" Height="1720">'
L '    <!-- 지정 위치 — 이름·개수(최대 4)는 장비 설정 Config\Machine.xml(현장마다), 값(mm)은 Config\TeachPositions.xml. 수동조작 창 지정 위치 줄·대기 위치 타일과 같은 목록 -->'
L '    <cnc:TeachPositionEditor Canvas.Left="204" Canvas.Top="12" Width="852" Height="468" access:Access.Level="5" MachineFile="Config\Machine.xml" TeachFile="Config\TeachPositions.xml" AxisLimits="X:-5:450;Y:-5:430;Z:-5:145" RowHeight="72" />'

$y1 = 496
L ''
L '    <!-- ===== 속도 ===== -->'
L "    <Border Canvas.Left=""204"" Canvas.Top=""$y1"" Width=""852"" Height=""270"" Style=""{StaticResource Card}"" />"
Text 224 ($y1 + 18) 'CardTitle' '속도'
Text 224 ($y1 + 88) 'RowHead' '수동 이동 속도'
Text 224 ($y1 + 110) 'Caption' 'mm/s'
Box 716 ($y1 + 76) 320 '::AsGlobalPV:gEquipment.Input.Parameter.SystemSpeed' 1 '1' '200' 64
Text 224 ($y1 + 188) 'RowHead' '속도 배율'
Text 224 ($y1 + 210) 'Caption' '%'
Box 716 ($y1 + 176) 320 '::AsGlobalPV:gEquipment.Input.Parameter.Feedrate' 0 '0' '150' 64

$y2 = 778
L ''
L '    <!-- ===== 축 소프트 리밋 ===== -->'
L "    <Border Canvas.Left=""204"" Canvas.Top=""$y2"" Width=""852"" Height=""372"" Style=""{StaticResource Card}"" />"
Text 224 ($y2 + 18) 'CardTitle' '축 소프트 리밋'
Text 352 ($y2 + 21) 'Caption' 'mm'
Text 476 ($y2 + 64) 'ColHead' '− 쪽' ' Width="270"'
Text 766 ($y2 + 64) 'ColHead' '+ 쪽' ' Width="270"'
$axes = @(@('X', 0), @('Y', 1), @('Z', 2))
for ($i = 0; $i -lt 3; $i++) {
  $ry = $y2 + 92 + $i * 92
  Text 224 ($ry + 20) 'RowHead' ($axes[$i][0] + '축')
  Box 476 $ry 270 ("::AsGlobalPV:gAxis[" + $axes[$i][1] + "].Input.Parameter.SoftwareLimitsNeg") 0 '-1000' '1000' 64
  Box 766 $ry 270 ("::AsGlobalPV:gAxis[" + $axes[$i][1] + "].Input.Parameter.SoftwareLimitsPos") 0 '-1000' '1000' 64
}

L ''
L '    <!-- ===== 공작물 영점(G54~G57, PLC 대기 — 잠김) — 「헤드 · 좌표계」 탭이 「플러그인」이 되며 옮겼다 ===== -->'
L '    <cnc:WorkOffsetCard Canvas.Left="204" Canvas.Top="1162" Width="852" Height="330" RowButtons="True" />'
L '    </Canvas>'

# ---- 탭 [플러그인] — 목록(플러그인 배치 · 헤드 플러그인 · + 플러그인 추가) 위, 자세히 아래 ----
L ''
L '    <!-- ===== 탭 [플러그인] — 헤드 고르기(헤드는 하나) · 값 · PLC 지금 · 3D 모델 · M 코드 · 고급, 플러그인 배치(작업현황 4 × 4 칸 78 %), + 플러그인 추가. 예전 헤드 구성 · 헤드 테이블을 대신한다 ===== -->'
L '    <Canvas x:Name="TabPlugin" Canvas.Left="0" Canvas.Top="0" Width="1080" Height="1720" Visibility="Collapsed">'
L '    <cnc:PluginScreen Canvas.Left="204" Canvas.Top="12" Width="852" Height="1692" Portrait="True" opc:OpcUaNode.ConnectionId="cnc-plc" HeadsFile="Config\Heads.xml" UsageFile="Database\HeadUsage.xml" LayoutFile="Config\PluginLayout.xml" GCodeConfigFile="Config\GCode.xml" CncFolderFile="Config\CncFolder.xml" AccessLevel="10" CurrentActionTag="::AsGlobalPV:gEquipment.Output.Status.CurrentAction" MovingTag="::AsGlobalPV:gEquipment.Output.State.Move" ProgramNameTag="::AsGlobalPV:gEquipment.Input.Parameter.sProgramName" />'
L '    </Canvas>'

# ---- 탭 [시스템] — 장비 이름 · 시스템 정보 · 설정 내보내기 / 가져오기 · HMI 다시 시작 ----
L ''
L '    <!-- ===== 탭 [시스템] — 장비 이름 기본 「범용 CNC」, 설정 · 다시 시작 ===== -->'
L '    <Canvas x:Name="TabSystem" Canvas.Left="0" Canvas.Top="0" Width="1080" Height="1720" Visibility="Collapsed">'
L '    <cnc:SystemSetupCard Canvas.Left="204" Canvas.Top="12" Width="852" Height="470" access:Access.Level="5" MachineFile="Config\Machine.xml" HeadsFile="Config\Heads.xml" AlarmsFile="alarms.json" Columns="2" InfoColumns="2" />'
L '    <cnc:MaintenanceCard Canvas.Left="204" Canvas.Top="494" Width="852" Height="136" opc:OpcUaNode.ConnectionId="cnc-plc" AccessLevel="10" CurrentActionTag="::AsGlobalPV:gEquipment.Output.Status.CurrentAction" MovingTag="::AsGlobalPV:gEquipment.Output.State.Move" />'
L '    </Canvas>'

L ''
L '    <!-- 왼쪽 네비 — 위치 · 속도 / 플러그인 / 시스템, 칸을 누르면 위 세 Canvas 중 하나만 보인다 -->'
L '    <cnc:ConfigTabBar Canvas.Left="24" Canvas.Top="12" Width="168" Height="208" Vertical="True" Labels="위치 · 속도|플러그인|시스템" Groups="TabPosition|TabPlugin|TabSystem" />'
L '</Canvas>'
[IO.File]::WriteAllText($Out, $sb.ToString().Replace("`r`n", "`n"), $utf8)
"rows=" + ($sb.ToString() -split "`n").Count
