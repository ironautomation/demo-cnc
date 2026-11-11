# 제3자 구성요소 고지 (Third-Party Notices)

이 저장소에 들어 있는 파일 중 일부는 다른 회사·개발자의 구성요소를 포함합니다.

## `src/HMI/Controls/CncControls.dll` 에 포함된 오픈소스

`CncControls.dll` 은 아래 라이브러리를 리소스로 포함(임베드)합니다. 두 라이브러리 모두 MIT 라이선스입니다.

| 구성요소 | 버전 | 라이선스 | 출처 |
|---|---|---|---|
| ScottPlot, ScottPlot.WPF | 5.0.55 | MIT | https://github.com/ScottPlot/ScottPlot |
| SkiaSharp.Views.WPF, SkiaSharp.Views.Desktop.Common, SkiaSharp.HarfBuzz | 2.88 | MIT | https://github.com/mono/SkiaSharp |

### ScottPlot

```
MIT License

Copyright (c) 2018 Scott Harden / Harden Technologies, LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### SkiaSharp

```
Copyright (c) 2015-2016 Xamarin, Inc.
Copyright (c) 2017-2018 Microsoft Corporation.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## 제조사 파일 (MIT 대상 아님)

| 파일 | 제공 | 비고 |
|---|---|---|
| `src/PLC/Logical/Libraries/` | B&R Industrial Automation | Automation Studio 프로젝트가 참조하는 B&R 라이브러리. B&R 의 이용 조건을 따릅니다 |
| `src/PLC/Physical/Config1/X20CP1684/ExternalHardware/INKJ8Z2T.ext` | YASKAWA Electric Corporation | 서보팩 SGDXT 의 EtherCAT 장치 기술 파일(ESI)을 Automation Studio 가 변환한 파일 |
| `src/PLC/Physical/Config1/X20CP1684/DTM/` | Automation Studio(Hilscher DTM) 생성 | EtherCAT 마스터 · 서보팩 구성 데이터 |
