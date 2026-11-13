# P09 Microsoft ApplicationLoopback 빌드 검증

이 폴더는 빌드와 정적 검사 결과다. ApplicationLoopback과 제품을 실행하거나 오디오를 녹음하지 않았다.

## 출처와 빌드

- [Microsoft Windows-classic-samples의 고정 커밋](https://github.com/microsoft/Windows-classic-samples/tree/434f6002bdf9cf9829406c3ff2b33387982d6168/Samples/ApplicationLoopback)의 샘플 전체와 저장소 루트 LICENSE를 보존했다. 다운로드한 10개 파일의 Git blob 해시를 동일 커밋의 GitHub 트리 API와 대조했다. 샘플에 적용되는 MIT 라이선스 (원본 실행 폴더 자료)
- upstream packages.config의 WIL 1.0.210204.1을 NuGet 공식 v3 flat container에서 받았다. 압축 파일 SHA-256은 4a29db9ba5b6a28315d737538cd15e77489126c38af0387cea5a90093badd4b6이며, SHA-512는 [NuGet 카탈로그](https://api.nuget.org/v3/catalog0/data/2021.02.04.21.44.24/microsoft.windows.implementationlibrary.1.0.210204.1.json)와 일치했다. 로컬 dotnet SDK 부재로 NuGet 서명 검증은 수행하지 못했다. 패키지에 포함된 .targets는 헤더 검색 경로만 추가한다. 패키지에 MIT LICENSE와 ThirdPartyNotices.txt가 포함돼 있다.
- 소스와 프로젝트 파일을 그대로 사용했다. VS18 x64 MSBuild에서 /t:Build /p:Configuration=Release /p:Platform=x64 /p:PlatformToolset=v145 /p:WindowsTargetPlatformVersion=10.0.26100.0 및 이 폴더의 별도 OutDir·IntDir를 명령줄로 지정했다. 프로젝트의 v142 기본값은 빌드 옵션으로 재지정했다. /p:ImportUserLocationsByWildcardBeforeMicrosoftCppProps=false /p:ImportUserLocationsByWildcardAfterMicrosoftCppProps=false 및 격리 UserRootDir을 사용했다. 빌드 로그 (원본 실행 폴더 자료)
- 경고 0건, 오류 0건. PE 검사 (원본 실행 폴더 자료)에서 8664 x64, PE32+, Windows CUI와 MFPlat, MMDevAPI, MSVC·UCRT 종속성을 확인했다. System32에서 MSVCP140.dll, VCRUNTIME140.dll, VCRUNTIME140_1.dll의 존재를 확인했다.

| 산출물 | 크기 | SHA-256 |
| --- | ---: | --- |
| ApplicationLoopback.exe (원본 실행 폴더 자료) | 51,200 B | 8234b65763c85047b49164070fed5f9e78a1b0c641deaba58d3ddfab12384b40 |
| ApplicationLoopback.pdb (원본 실행 폴더 자료) | 1,617,920 B | d4a5ff6a8cedc5812f26d5f97697f4f79dd75d678f06e99c71481c40782d29d6 |

## 증거 범위

- includetree는 VIRTUAL_AUDIO_DEVICE_PROCESS_LOOPBACK으로 대상 PID와 하위 프로세스의 렌더링 오디오를 수집한다. Windows의 지정 출력 엔드포인트 루프백은 해당 엔드포인트의 전체 앱 믹스를 수집한다. 실제 물리 출력과 선택한 장치의 출력 여부를 판정하려면 별도의 장치 증거가 필요하다. excludetree는 대상 트리 밖의 소리를 수집하므로 이 검증의 제품 오디오 귀속에 부적합하다. Windows 빌드 20348 이상이 필요하다. [Microsoft Learn](https://learn.microsoft.com/en-us/samples/microsoft/windows-classic-samples/applicationloopbackaudio-sample/)
- 샘플은 시작 요청 후 Sleep(10000)을 호출하며 44.1 kHz, 16-bit, 2채널 PCM WAV를 쓴다. 정확한 시작은 비동기 콜백에서 처리한다. 출력 경로는 CREATE_ALWAYS로 열며 경로가 이미 존재하면 덮어쓴다. wmain은 사용법 오류와 StartCaptureAsync 오류에서도 0을 반환하고 StopCaptureAsync의 반환값을 확인하지 않는다. 실제 검증 시 콘솔 메시지, WAV 헤더·데이터 길이, 제품 PID/트리, 수집과 화면 전환의 UTC를 대조해야 한다. 명령행 처리 (원본 실행 폴더 자료) · 수집 구현 (원본 실행 폴더 자료)
- 샘플은 캡처 패킷의 타임스탬프와 플래그를 WAV에 기록하지 않고 SILENT 및 DATA_DISCONTINUITY를 별도 처리하지 않는다. WAV의 무음이나 중간 공백은 독립 시간 기록과 수집 성공 근거를 함께 확인해야 해석할 수 있다. 타이틀이나 지도가 새로 재생한 음악, 이전 화면 오디오의 잔류, 내부 오디오 리소스 해제는 파형만으로 구별할 수 없다. 후속 실측에서 각 전환·종료 전후가 10초 구간에 들어오는지 확인해야 한다.
