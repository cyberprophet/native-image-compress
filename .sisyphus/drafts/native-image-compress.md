# Draft: Flutter Native Image Compress Package

## Requirements (confirmed)
- **Platforms**: Android, iOS, macOS, Windows, Web (5개)
- **Core Function**: 이미지 리사이징 + 압축
- **Resize Logic**: 
  - 최대 가로/세로 크기 지정
  - 비율 유지하면서 축소
  - 지정 크기보다 작으면 리사이징 없이 압축만
- **Compression**: 
  - 사용자 조절 가능
  - 기본값 70%
- **Implementation**: 각 플랫폼 네이티브 API 사용 (Dart 압축 X)

## Technical Decisions
- **입력 포맷**: JPEG, PNG만 지원
- **출력 포맷**: 입력 포맷 유지 (JPEG→JPEG, PNG→PNG)
- **I/O 방식**: 둘 다 지원 (Uint8List + 파일 경로)
- **배치 처리**: 불필요 (단일 이미지만)
- **PNG 처리**: 리사이징만 (quality 파라미터 무시)
- **반환값**: 데이터만 (Uint8List 또는 파일 경로)
- **에러 처리**: Exception throw
- **테스트 전략**: 구현 후 테스트 추가
- **Android minSdk**: Flutter 기본값 (21) - BitmapFactory + ImageDecoder 분기 필요
- **파라미터 검증**: 클램프 (quality 0-100, maxWidth/maxHeight > 0)

## Research Findings
### Native APIs per Platform:
- **Android**: Bitmap.compress() / ImageDecoder (API 29+)
- **iOS/macOS**: ImageIO framework / UIImage.jpegData()
- **Windows**: WIC (Windows Imaging Component)
- **Web**: Canvas.toBlob() / OffscreenCanvas

### Format Support:
- Universal: JPEG, PNG
- Modern: WebP (대부분 지원)
- Advanced: HEIF, AVIF (플랫폼별 상이)

## Open Questions
1. 지원할 입력 이미지 포맷은?
2. 출력 포맷은 입력과 동일? 또는 특정 포맷으로 변환?
3. 입력/출력 방식: 파일 경로? 메모리 바이트(Uint8List)?
4. 배치 처리(여러 이미지 동시 처리) 필요?
5. 압축 결과 정보 반환 형태? (파일 경로만? 메타데이터 포함?)

## Scope Boundaries
- INCLUDE: (pending)
- EXCLUDE: (pending)
