# Flutter Native Image Compress Package

## TL;DR

> **Quick Summary**: 5개 플랫폼(Android, iOS, macOS, Windows, Web)에서 네이티브 API를 사용하여 JPEG/PNG 이미지를 리사이징하고 압축하는 Flutter 패키지 개발
> 
> **Deliverables**:
> - Dart API: `compress()` (메모리), `compressFile()` (파일 경로) 메서드
> - Android: Kotlin + BitmapFactory/ImageDecoder
> - iOS: Swift + ImageIO
> - macOS: Swift + ImageIO
> - Windows: C++ + WIC
> - Web: Dart + Canvas API
> - 예제 앱 + 단위/통합 테스트
> 
> **Estimated Effort**: Large
> **Parallel Execution**: YES - 4 waves
> **Critical Path**: Task 1 → Task 2 → Task 3 → Tasks 4-8 (parallel) → Task 9 → Task 10

---

## Context

### Original Request
Flutter 패키지를 만들어서 5개 플랫폼(Android, iOS, macOS, Windows, Web)에서 네이티브 방식으로 이미지를 리사이징하고 압축. 최대 가로/세로 크기 지정, 비율 유지, 작은 이미지는 압축만. 압축률 기본값 70%.

### Interview Summary
**Key Discussions**:
- 입력 포맷: JPEG, PNG만 지원
- 출력 포맷: 입력 포맷 유지 (JPEG→JPEG, PNG→PNG)
- I/O 방식: Uint8List(메모리) + 파일 경로 둘 다 지원
- PNG 처리: 리사이징만 (무손실이라 quality 적용 안됨)
- 반환값: 데이터만 (Uint8List)
- 에러 처리: Exception throw
- 배치 처리: 불필요
- Android minSdk: Flutter 기본값 (21) - BitmapFactory + ImageDecoder 분기 필요
- 파라미터 검증: 클램프 (quality 0-100, maxWidth/maxHeight > 0)

**Research Findings**:
- Android: Bitmap.compress() (legacy) / ImageDecoder (API 28+)
- iOS/macOS: ImageIO framework / UIImage.jpegData()
- Windows: WIC (Windows Imaging Component)
- Web: Canvas.toBlob()

### Metis Review
**Identified Gaps** (addressed):
- pubspec.yaml 플랫폼 설정이 placeholder 상태 → Task 1에서 수정
- 스레딩 전략 미정 → 각 플랫폼 백그라운드 스레드 처리
- 파라미터 검증 방식 → Dart 레벨에서 클램프 처리
- EXIF orientation → 플랫폼 기본 동작 따름
- iOS/macOS 코드 공유 → 각각 독립 구현

---

## Work Objectives

### Core Objective
각 플랫폼의 네이티브 API를 사용하여 이미지 리사이징/압축을 수행하는 Flutter 플러그인 완성

### Concrete Deliverables
- `lib/flutter_native_image_compress.dart` - 메인 API
- `lib/flutter_native_image_compress_platform_interface.dart` - 플랫폼 인터페이스
- `lib/flutter_native_image_compress_method_channel.dart` - Method Channel 구현
- `lib/flutter_native_image_compress_web.dart` - Web 구현
- `lib/src/compress_options.dart` - 옵션 모델
- `lib/src/image_compress_exception.dart` - 예외 클래스
- `android/src/main/kotlin/.../FlutterNativeImageCompressPlugin.kt` - Android 구현
- `ios/Classes/FlutterNativeImageCompressPlugin.swift` - iOS 구현
- `macos/Classes/FlutterNativeImageCompressPlugin.swift` - macOS 구현
- `windows/flutter_native_image_compress_plugin.cpp` - Windows 구현
- `example/lib/main.dart` - 예제 앱
- `test/*.dart` - 단위 테스트

### Definition of Done
- [ ] `flutter analyze lib/` → No issues found
- [ ] `flutter test` → All tests passed
- [ ] `cd example && flutter build apk --debug` → SUCCESS
- [ ] `cd example && flutter build ios --debug --no-codesign` → SUCCESS
- [ ] `cd example && flutter build macos --debug` → SUCCESS
- [ ] `cd example && flutter build windows --debug` → SUCCESS
- [ ] `cd example && flutter build web --debug` → SUCCESS

### Must Have
- JPEG 압축 (quality 0-100, 기본값 70)
- PNG 리사이징 (압축 없음)
- 최대 가로/세로 크기 제한 (비율 유지)
- 작은 이미지는 리사이징 없이 반환
- 메모리 기반 API (Uint8List → Uint8List)
- 파일 경로 기반 API (String → Uint8List)
- 각 플랫폼 네이티브 압축 (Dart 압축 X)

### Must NOT Have (Guardrails)
- ❌ GIF, WebP, HEIC, BMP 지원
- ❌ 이미지 포맷 변환 (JPEG→PNG, PNG→JPEG)
- ❌ 이미지 회전, 크롭, 필터 기능
- ❌ 메타데이터 반환 (width, height, size 등)
- ❌ 배치 처리 (여러 이미지 동시 처리)
- ❌ 프로그레스 콜백
- ❌ 외부 네이티브 라이브러리 (libjpeg, libpng 등)
- ❌ FFI/dart:ffi 사용
- ❌ iOS/macOS 코드 공유 (각각 구현)

---

## Verification Strategy

> **UNIVERSAL RULE: ZERO HUMAN INTERVENTION**
>
> 모든 태스크는 사람의 개입 없이 자동 검증 가능해야 함.
> "사용자가 확인..." 같은 기준 금지.

### Test Decision
- **Infrastructure exists**: YES
- **Automated tests**: YES (Tests-after)
- **Framework**: flutter_test + integration_test

### Agent-Executed QA Scenarios (MANDATORY)

각 태스크마다 Agent가 직접 실행하여 검증. 플랫폼별:
- **Dart/Flutter**: `flutter analyze`, `flutter test`, `flutter build`
- **실제 동작 테스트**: 예제 앱 실행 후 이미지 처리 결과 확인

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately):
└── Task 1: pubspec.yaml 플랫폼 설정 수정

Wave 2 (After Wave 1):
└── Task 2: Dart API 설계 (인터페이스, 모델, Exception)

Wave 3 (After Wave 2):
└── Task 3: Method Channel 구현 + Web 구현

Wave 4 (After Wave 3) - PARALLEL:
├── Task 4: Android 네이티브 구현
├── Task 5: iOS 네이티브 구현
├── Task 6: macOS 네이티브 구현
├── Task 7: Windows 네이티브 구현
└── Task 8: (Web은 Task 3에서 완료)

Wave 5 (After Wave 4):
└── Task 9: 예제 앱 업데이트

Wave 6 (After Wave 5):
└── Task 10: 테스트 코드 작성
```

### Dependency Matrix

| Task | Depends On | Blocks | Can Parallelize With |
|------|------------|--------|---------------------|
| 1 | None | 2 | None |
| 2 | 1 | 3 | None |
| 3 | 2 | 4,5,6,7 | None |
| 4 | 3 | 9 | 5, 6, 7 |
| 5 | 3 | 9 | 4, 6, 7 |
| 6 | 3 | 9 | 4, 5, 7 |
| 7 | 3 | 9 | 4, 5, 6 |
| 9 | 4,5,6,7 | 10 | None |
| 10 | 9 | None | None |

### Agent Dispatch Summary

| Wave | Tasks | Recommended Agents |
|------|-------|-------------------|
| 1 | 1 | quick |
| 2 | 2 | unspecified-low |
| 3 | 3 | unspecified-low |
| 4 | 4,5,6,7 | 4개 병렬 dispatch (unspecified-high each) |
| 5 | 9 | quick |
| 6 | 10 | unspecified-low |

---

## TODOs

- [x] 1. pubspec.yaml 플랫폼 설정 수정

  **What to do**:
  - `pubspec.yaml`의 `flutter.plugin.platforms` 섹션에서 placeholder (`some_platform`) 제거
  - 5개 플랫폼 (android, ios, macos, windows, web) 설정 추가
  - 각 플랫폼별 pluginClass, package(android), fileName(web) 지정

  **Must NOT do**:
  - 다른 파일 수정 금지
  - 의존성 추가 금지

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 단일 파일의 간단한 YAML 수정
  - **Skills**: `[]`
    - 특별한 스킬 불필요

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (Wave 1)
  - **Blocks**: Task 2
  - **Blocked By**: None

  **References**:
  - `pubspec.yaml:35-44` - 현재 placeholder 설정 위치
  - Flutter Plugin 문서: https://docs.flutter.dev/packages-and-plugins/developing-packages#plugin-platforms

  **Acceptance Criteria**:
  - [ ] `flutter pub get` → SUCCESS (pubspec.yaml 유효)
  - [ ] `flutter analyze` → No platform configuration errors

  **Agent-Executed QA Scenarios**:

  ```
  Scenario: pubspec.yaml 유효성 검증
    Tool: Bash
    Preconditions: None
    Steps:
      1. cd /home/cyberprophet/source/dart/flutter_native_image_compress
      2. flutter pub get
      3. Assert: exit code 0
      4. flutter analyze lib/
      5. Assert: No "plugin" related errors
    Expected Result: 의존성 해결 성공, 분석 통과
    Evidence: 명령 출력 캡처
  ```

  **Commit**: YES
  - Message: `feat(plugin): configure platform targets for android, ios, macos, windows, web`
  - Files: `pubspec.yaml`
  - Pre-commit: `flutter pub get`

---

- [x] 2. Dart API 설계 (인터페이스, 모델, Exception)

  **What to do**:
  - `lib/src/compress_options.dart` 생성 - CompressOptions 모델 클래스
    ```dart
    class CompressOptions {
      final int? maxWidth;      // null이면 무제한
      final int? maxHeight;     // null이면 무제한  
      final int quality;        // 0-100, 기본 70 (JPEG만 적용)
      // 생성자에서 클램프 처리
    }
    ```
  - `lib/src/image_compress_exception.dart` 생성 - 예외 클래스
    ```dart
    class ImageCompressException implements Exception {
      final String message;
      final String? code;
    }
    ```
  - `lib/flutter_native_image_compress_platform_interface.dart` 수정
    - `compress(Uint8List data, CompressOptions options)` 메서드 추가
    - `compressFile(String path, CompressOptions options)` 메서드 추가
  - `lib/flutter_native_image_compress.dart` 수정
    - 퍼블릭 API로 compress, compressFile 노출
    - export 문 추가

  **Must NOT do**:
  - Method Channel 구현 (Task 3에서)
  - 네이티브 코드 수정 금지
  - 메타데이터 반환 기능 추가 금지

  **Recommended Agent Profile**:
  - **Category**: `unspecified-low`
    - Reason: 표준 Dart 코드 작성, 복잡하지 않음
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (Wave 2)
  - **Blocks**: Task 3
  - **Blocked By**: Task 1

  **References**:
  - `lib/flutter_native_image_compress_platform_interface.dart` - 현재 인터페이스 구조
  - `lib/flutter_native_image_compress.dart` - 현재 메인 클래스

  **Acceptance Criteria**:
  - [ ] `lib/src/compress_options.dart` 파일 존재
  - [ ] `lib/src/image_compress_exception.dart` 파일 존재
  - [ ] `flutter analyze lib/` → No issues found
  - [ ] CompressOptions에서 quality 150 → 100으로 클램프 확인
  - [ ] CompressOptions에서 quality -10 → 0으로 클램프 확인

  **Agent-Executed QA Scenarios**:

  ```
  Scenario: Dart API 구조 검증
    Tool: Bash
    Steps:
      1. flutter analyze lib/
      2. Assert: No issues found
      3. dart run --enable-asserts -e "
         import 'package:flutter_native_image_compress/flutter_native_image_compress.dart';
         final opts = CompressOptions(quality: 150);
         assert(opts.quality == 100);
         print('Quality clamp OK');
         "
      4. Assert: "Quality clamp OK" in output
    Expected Result: 분석 통과, 클램프 동작 확인
    Evidence: 명령 출력 캡처
  ```

  **Commit**: YES
  - Message: `feat(api): add CompressOptions model and platform interface methods`
  - Files: `lib/src/compress_options.dart`, `lib/src/image_compress_exception.dart`, `lib/flutter_native_image_compress_platform_interface.dart`, `lib/flutter_native_image_compress.dart`
  - Pre-commit: `flutter analyze lib/`

---

- [x] 3. Method Channel 구현 + Web 구현

  **What to do**:
  - `lib/flutter_native_image_compress_method_channel.dart` 수정
    - compress() 메서드 구현 - MethodChannel.invokeMethod('compress', {...})
    - compressFile() 메서드 구현 - MethodChannel.invokeMethod('compressFile', {...})
    - PlatformException을 ImageCompressException으로 변환
  - `lib/flutter_native_image_compress_web.dart` 수정
    - WebFlutterNativeImageCompressPlugin 클래스 구현
    - Canvas API를 사용한 압축 구현
    - registerWith 메서드로 플러그인 등록
  - Web 구현 세부사항:
    - Uint8List → Blob → Image → Canvas → toBlob → Uint8List
    - PNG는 리사이징만, JPEG는 quality 적용
    - 이미지 포맷 감지 (매직 바이트: JPEG=FFD8, PNG=89504E47)

  **Must NOT do**:
  - 네이티브 코드 수정 금지 (별도 태스크)
  - Web Worker 사용 금지 (복잡도 증가)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-low`
    - Reason: Method Channel 패턴 및 Web API 사용
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (Wave 3)
  - **Blocks**: Tasks 4, 5, 6, 7
  - **Blocked By**: Task 2

  **References**:
  - `lib/flutter_native_image_compress_method_channel.dart` - 현재 구조
  - `lib/flutter_native_image_compress_web.dart` - 현재 구조 (에러 있음, 수정 필요)
  - Flutter Web Plugin: https://docs.flutter.dev/packages-and-plugins/developing-packages#web-plugin

  **Acceptance Criteria**:
  - [ ] `flutter analyze lib/` → No issues found
  - [ ] Method Channel에서 compress, compressFile 메서드 호출 가능
  - [ ] Web 플러그인에서 compress 메서드 구현됨
  - [ ] `cd example && flutter build web --debug` → SUCCESS

  **Agent-Executed QA Scenarios**:

  ```
  Scenario: Web 빌드 검증
    Tool: Bash
    Steps:
      1. cd example
      2. flutter build web --debug
      3. Assert: exit code 0
      4. ls build/web/main.dart.js
      5. Assert: file exists
    Expected Result: Web 빌드 성공
    Evidence: 빌드 출력 캡처
  ```

  **Commit**: YES
  - Message: `feat(channel): implement method channel and web platform`
  - Files: `lib/flutter_native_image_compress_method_channel.dart`, `lib/flutter_native_image_compress_web.dart`
  - Pre-commit: `flutter analyze lib/`

---

- [x] 4. Android 네이티브 구현

  **What to do**:
  - `android/src/main/kotlin/.../FlutterNativeImageCompressPlugin.kt` 수정
  - Method Channel 핸들러 구현:
    - `compress` 메서드: Uint8List 입력 → 압축 → Uint8List 반환
    - `compressFile` 메서드: 파일 경로 입력 → 압축 → Uint8List 반환
  - 이미지 처리 로직:
    - BitmapFactory.decodeByteArray() 또는 ImageDecoder (API 28+)
    - 리사이징: Bitmap.createScaledBitmap() (비율 유지)
    - 압축: Bitmap.compress(format, quality, outputStream)
    - 포맷 감지: BitmapFactory.Options.outMimeType
  - 스레딩: Kotlin Coroutine 또는 백그라운드 스레드에서 처리
  - PNG는 quality 무시, JPEG만 적용

  **Must NOT do**:
  - 외부 라이브러리 추가 금지
  - minSdk 변경 금지 (Flutter 기본값 21 유지)
  - WebP, HEIC 등 다른 포맷 처리 금지

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: 네이티브 Kotlin 코드, 이미지 처리 로직
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 4 (with Tasks 5, 6, 7)
  - **Blocks**: Task 9
  - **Blocked By**: Task 3

  **References**:
  - `android/src/main/kotlin/com/example/flutter_native_image_compress/FlutterNativeImageCompressPlugin.kt` - 현재 보일러플레이트
  - `android/build.gradle` - 빌드 설정
  - Android Bitmap 문서: https://developer.android.com/reference/android/graphics/Bitmap

  **Acceptance Criteria**:
  - [ ] `cd example && flutter build apk --debug` → SUCCESS
  - [ ] compress 메서드가 JPEG 이미지 압축 수행
  - [ ] compressFile 메서드가 파일 경로에서 이미지 로드 및 압축
  - [ ] 리사이징 시 비율 유지됨
  - [ ] PNG는 리사이징만 (quality 무시)

  **Agent-Executed QA Scenarios**:

  ```
  Scenario: Android APK 빌드 성공
    Tool: Bash
    Steps:
      1. cd example
      2. flutter build apk --debug
      3. Assert: exit code 0
      4. ls build/app/outputs/flutter-apk/app-debug.apk
      5. Assert: file exists
    Expected Result: APK 빌드 성공
    Evidence: 빌드 출력 캡처

  Scenario: Android 코드 컴파일 검증
    Tool: Bash
    Steps:
      1. cd example/android
      2. ./gradlew :flutter_native_image_compress:compileDebugKotlin
      3. Assert: BUILD SUCCESSFUL
    Expected Result: Kotlin 컴파일 성공
    Evidence: Gradle 출력 캡처
  ```

  **Commit**: YES
  - Message: `feat(android): implement native image compression with BitmapFactory`
  - Files: `android/src/main/kotlin/com/example/flutter_native_image_compress/FlutterNativeImageCompressPlugin.kt`
  - Pre-commit: `cd example && flutter build apk --debug`

---

- [x] 5. iOS 네이티브 구현

  **What to do**:
  - `ios/Classes/FlutterNativeImageCompressPlugin.swift` 수정
  - Method Channel 핸들러 구현:
    - `compress` 메서드: FlutterStandardTypedData 입력 → 압축 → FlutterStandardTypedData 반환
    - `compressFile` 메서드: 파일 경로 입력 → 압축 → FlutterStandardTypedData 반환
  - 이미지 처리 로직:
    - UIImage(data:) 또는 ImageIO로 로드
    - 리사이징: UIGraphicsImageRenderer 또는 Core Graphics
    - 압축: UIImage.jpegData(compressionQuality:) 또는 CGImageDestination
    - 포맷 감지: CGImageSourceCopyTypeIdentifier
  - 스레딩: DispatchQueue.global(qos: .userInitiated).async
  - PNG는 UIImage.pngData() 사용 (quality 무시)

  **Must NOT do**:
  - 외부 라이브러리/CocoaPods 추가 금지
  - macOS 코드와 공유 금지 (별도 구현)
  - HEIC 변환 시도 금지

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: 네이티브 Swift 코드, UIKit/ImageIO
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 4 (with Tasks 4, 6, 7)
  - **Blocks**: Task 9
  - **Blocked By**: Task 3

  **References**:
  - `ios/Classes/FlutterNativeImageCompressPlugin.swift` - 현재 보일러플레이트
  - `ios/flutter_native_image_compress.podspec` - CocoaPods 설정
  - Apple UIImage 문서: https://developer.apple.com/documentation/uikit/uiimage

  **Acceptance Criteria**:
  - [ ] `cd example && flutter build ios --debug --no-codesign` → SUCCESS
  - [ ] compress 메서드가 JPEG 이미지 압축 수행
  - [ ] compressFile 메서드가 파일 경로에서 이미지 로드 및 압축
  - [ ] 리사이징 시 비율 유지됨
  - [ ] PNG는 리사이징만 (quality 무시)

  **Agent-Executed QA Scenarios**:

  ```
  Scenario: iOS 빌드 성공
    Tool: Bash
    Steps:
      1. cd example
      2. flutter build ios --debug --no-codesign
      3. Assert: exit code 0
    Expected Result: iOS 빌드 성공
    Evidence: 빌드 출력 캡처

  Scenario: Swift 컴파일 검증
    Tool: Bash
    Steps:
      1. cd example/ios
      2. xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
      3. Assert: BUILD SUCCEEDED
    Expected Result: Xcode 빌드 성공
    Evidence: xcodebuild 출력 캡처
  ```

  **Commit**: YES
  - Message: `feat(ios): implement native image compression with UIImage and ImageIO`
  - Files: `ios/Classes/FlutterNativeImageCompressPlugin.swift`
  - Pre-commit: `cd example && flutter build ios --debug --no-codesign`

---

- [x] 6. macOS 네이티브 구현

  **What to do**:
  - `macos/Classes/FlutterNativeImageCompressPlugin.swift` 수정
  - Method Channel 핸들러 구현 (iOS와 유사하나 NSImage 사용):
    - `compress` 메서드: FlutterStandardTypedData 입력 → 압축 → FlutterStandardTypedData 반환
    - `compressFile` 메서드: 파일 경로 입력 → 압축 → FlutterStandardTypedData 반환
  - 이미지 처리 로직:
    - NSImage(data:) 또는 ImageIO로 로드
    - 리사이징: NSImage resize 또는 Core Graphics
    - 압축: NSBitmapImageRep.representation(using:properties:)
    - 포맷 감지: CGImageSourceCopyTypeIdentifier
  - 스레딩: DispatchQueue.global(qos: .userInitiated).async
  - PNG는 NSBitmapImageRep.png 사용

  **Must NOT do**:
  - 외부 라이브러리 추가 금지
  - iOS 코드 복사/공유 금지 (유사하지만 별도 구현)
  - AppKit 외 프레임워크 사용 금지

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: 네이티브 Swift 코드, AppKit/ImageIO
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 4 (with Tasks 4, 5, 7)
  - **Blocks**: Task 9
  - **Blocked By**: Task 3

  **References**:
  - `macos/Classes/FlutterNativeImageCompressPlugin.swift` - 현재 보일러플레이트
  - `macos/flutter_native_image_compress.podspec` - CocoaPods 설정
  - Apple NSImage 문서: https://developer.apple.com/documentation/appkit/nsimage

  **Acceptance Criteria**:
  - [ ] `cd example && flutter build macos --debug` → SUCCESS
  - [ ] compress 메서드가 JPEG 이미지 압축 수행
  - [ ] compressFile 메서드가 파일 경로에서 이미지 로드 및 압축
  - [ ] 리사이징 시 비율 유지됨
  - [ ] PNG는 리사이징만 (quality 무시)

  **Agent-Executed QA Scenarios**:

  ```
  Scenario: macOS 빌드 성공
    Tool: Bash
    Steps:
      1. cd example
      2. flutter build macos --debug
      3. Assert: exit code 0
      4. ls build/macos/Build/Products/Debug/flutter_native_image_compress_example.app
      5. Assert: directory exists
    Expected Result: macOS 앱 빌드 성공
    Evidence: 빌드 출력 캡처
  ```

  **Commit**: YES
  - Message: `feat(macos): implement native image compression with NSImage and ImageIO`
  - Files: `macos/Classes/FlutterNativeImageCompressPlugin.swift`
  - Pre-commit: `cd example && flutter build macos --debug`

---

- [x] 7. Windows 네이티브 구현

  **What to do**:
  - `windows/flutter_native_image_compress_plugin.cpp` 수정
  - `windows/flutter_native_image_compress_plugin.h` 필요시 수정
  - Method Channel 핸들러 구현:
    - `compress` 메서드: std::vector<uint8_t> 입력 → 압축 → std::vector<uint8_t> 반환
    - `compressFile` 메서드: 파일 경로(wstring) 입력 → 압축 → std::vector<uint8_t> 반환
  - WIC (Windows Imaging Component) 사용:
    - IWICImagingFactory, IWICBitmapDecoder, IWICBitmapEncoder
    - 리사이징: IWICBitmapScaler
    - 압축: IWICBitmapEncoder with JPEG quality option
    - 포맷 감지: IWICBitmapDecoder container format
  - COM 초기화 필요 (CoInitializeEx)
  - PNG는 IWICBitmapEncoder with PNG codec

  **Must NOT do**:
  - 외부 라이브러리 추가 금지 (WIC는 Windows 기본 제공)
  - GDI+ 사용 금지 (deprecated)
  - UTF-8/UTF-16 인코딩 문제 주의 (한글 경로)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: 네이티브 C++ 코드, WIC API
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 4 (with Tasks 4, 5, 6)
  - **Blocks**: Task 9
  - **Blocked By**: Task 3

  **References**:
  - `windows/flutter_native_image_compress_plugin.cpp` - 현재 보일러플레이트
  - `windows/CMakeLists.txt` - CMake 설정
  - WIC 문서: https://learn.microsoft.com/en-us/windows/win32/wic/-wic-about-windows-imaging-codec

  **Acceptance Criteria**:
  - [ ] `cd example && flutter build windows --debug` → SUCCESS
  - [ ] compress 메서드가 JPEG 이미지 압축 수행
  - [ ] compressFile 메서드가 파일 경로에서 이미지 로드 및 압축
  - [ ] 리사이징 시 비율 유지됨
  - [ ] PNG는 리사이징만

  **Agent-Executed QA Scenarios**:

  ```
  Scenario: Windows 빌드 성공
    Tool: Bash
    Steps:
      1. cd example
      2. flutter build windows --debug
      3. Assert: exit code 0
      4. ls build/windows/x64/runner/Debug/flutter_native_image_compress_example.exe
      5. Assert: file exists
    Expected Result: Windows exe 빌드 성공
    Evidence: 빌드 출력 캡처
  ```

  **Commit**: YES
  - Message: `feat(windows): implement native image compression with WIC`
  - Files: `windows/flutter_native_image_compress_plugin.cpp`, `windows/flutter_native_image_compress_plugin.h`, `windows/CMakeLists.txt`
  - Pre-commit: `cd example && flutter build windows --debug`

---

- [x] 8. (Reserved - Web은 Task 3에서 완료)

  **What to do**: 
  - Task 3에서 Web 구현 완료됨
  - 이 태스크는 placeholder로 유지

  **Status**: SKIP (Task 3에 통합)

---

- [x] 9. 예제 앱 업데이트

  **What to do**:
  - `example/lib/main.dart` 수정
  - 간단한 UI 구성:
    - 이미지 선택 버튼 (갤러리/파일에서)
    - 압축 옵션 입력 (maxWidth, maxHeight, quality)
    - 압축 버튼
    - 결과 표시 (원본/압축 이미지, 크기 비교)
  - image_picker 또는 file_picker 의존성 추가
  - 메모리 API와 파일 API 둘 다 테스트 가능하도록

  **Must NOT do**:
  - 복잡한 UI 금지 (간단한 데모만)
  - 배치 처리 UI 금지
  - 다른 플러그인 기능 테스트 금지

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 간단한 Flutter UI 코드
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (Wave 5)
  - **Blocks**: Task 10
  - **Blocked By**: Tasks 4, 5, 6, 7

  **References**:
  - `example/lib/main.dart` - 현재 보일러플레이트
  - `example/pubspec.yaml` - 예제 앱 의존성

  **Acceptance Criteria**:
  - [ ] 예제 앱이 이미지 선택 UI 제공
  - [ ] 압축 옵션 입력 가능
  - [ ] 압축 실행 및 결과 표시
  - [ ] `cd example && flutter analyze lib/` → No issues

  **Agent-Executed QA Scenarios**:

  ```
  Scenario: 예제 앱 분석 통과
    Tool: Bash
    Steps:
      1. cd example
      2. flutter pub get
      3. flutter analyze lib/
      4. Assert: No issues found
    Expected Result: 예제 앱 코드 분석 통과
    Evidence: analyze 출력 캡처
  ```

  **Commit**: YES
  - Message: `feat(example): add demo app with image picker and compression UI`
  - Files: `example/lib/main.dart`, `example/pubspec.yaml`
  - Pre-commit: `cd example && flutter analyze lib/`

---

- [x] 10. 테스트 코드 작성

  **What to do**:
  - `test/flutter_native_image_compress_test.dart` 수정
    - CompressOptions 클램프 테스트
    - Platform interface mock 테스트
  - `test/compress_options_test.dart` 생성
    - quality 클램프 (0-100)
    - maxWidth/maxHeight null 허용
  - `example/integration_test/plugin_integration_test.dart` 수정
    - 실제 이미지 압축 통합 테스트 (플랫폼별)
  - 테스트용 이미지 파일 추가 (example/assets/)

  **Must NOT do**:
  - 네이티브 코드 단위 테스트 (플랫폼별 테스트 도구 필요)
  - 100% 커버리지 목표 금지 (핵심 기능만)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-low`
    - Reason: Flutter 테스트 코드 작성
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (Wave 6)
  - **Blocks**: None
  - **Blocked By**: Task 9

  **References**:
  - `test/flutter_native_image_compress_test.dart` - 현재 테스트 구조
  - `example/integration_test/plugin_integration_test.dart` - 통합 테스트

  **Acceptance Criteria**:
  - [ ] `flutter test` → All tests passed
  - [ ] CompressOptions 클램프 테스트 통과
  - [ ] Mock platform 테스트 통과

  **Agent-Executed QA Scenarios**:

  ```
  Scenario: 단위 테스트 실행
    Tool: Bash
    Steps:
      1. flutter test
      2. Assert: All tests passed
      3. Assert: exit code 0
    Expected Result: 모든 테스트 통과
    Evidence: 테스트 출력 캡처

  Scenario: 테스트 커버리지 확인
    Tool: Bash
    Steps:
      1. flutter test --coverage
      2. Assert: coverage/lcov.info 생성됨
    Expected Result: 커버리지 리포트 생성
    Evidence: lcov.info 파일 확인
  ```

  **Commit**: YES
  - Message: `test: add unit tests for CompressOptions and platform interface`
  - Files: `test/flutter_native_image_compress_test.dart`, `test/compress_options_test.dart`, `example/integration_test/plugin_integration_test.dart`
  - Pre-commit: `flutter test`

---

## Commit Strategy

| After Task | Message | Files | Verification |
|------------|---------|-------|--------------|
| 1 | `feat(plugin): configure platform targets` | pubspec.yaml | flutter pub get |
| 2 | `feat(api): add CompressOptions and interface` | lib/src/*.dart, lib/*.dart | flutter analyze |
| 3 | `feat(channel): implement method channel and web` | lib/*.dart | flutter build web |
| 4 | `feat(android): implement native compression` | android/**/*.kt | flutter build apk |
| 5 | `feat(ios): implement native compression` | ios/**/*.swift | flutter build ios |
| 6 | `feat(macos): implement native compression` | macos/**/*.swift | flutter build macos |
| 7 | `feat(windows): implement native compression` | windows/**/*.cpp | flutter build windows |
| 9 | `feat(example): add demo app` | example/**/* | flutter analyze |
| 10 | `test: add unit and integration tests` | test/**/*.dart | flutter test |

---

## Success Criteria

### Verification Commands
```bash
# Dart 분석
flutter analyze lib/
# Expected: No issues found

# 테스트
flutter test
# Expected: All tests passed

# 각 플랫폼 빌드
cd example
flutter build apk --debug      # Android
flutter build ios --debug --no-codesign  # iOS
flutter build macos --debug    # macOS
flutter build windows --debug  # Windows
flutter build web --debug      # Web
# Expected: 모두 SUCCESS
```

### Final Checklist
- [ ] 5개 플랫폼 모두 빌드 성공
- [ ] JPEG 압축 동작 (quality 적용)
- [ ] PNG 리사이징 동작 (quality 무시)
- [ ] 비율 유지 리사이징 동작
- [ ] 작은 이미지는 리사이징 없이 반환
- [ ] 메모리 API (compress) 동작
- [ ] 파일 API (compressFile) 동작
- [ ] 파라미터 클램프 동작
- [ ] 예제 앱 실행 가능
- [ ] 테스트 통과
