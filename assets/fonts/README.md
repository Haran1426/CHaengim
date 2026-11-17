# 앱 글꼴

제목·본문·버튼·D-day를 **Noto Sans KR**로 통일합니다. 본문은 Regular, 조작 요소는 Medium/SemiBold, 큰 제목·마감 숫자는 Bold로 구분합니다. 폰트는 원본 그대로 포함하며 실행 중 다운로드하지 않습니다.

## 참고한 화면

- 사용자 지정: [라이드](https://ride.bz/) 모바일 앱의 차량비 수납 관리 화면. 제목과 본문의 크기·굵기를 참고했습니다.
- 글꼴명 확인 범위: [라이드 공개 PC 앱](https://pc.ride.bz/)의 [FontManifest.json](https://pc.ride.bz/assets/FontManifest.json). `NotoSans` 패밀리에 Noto Sans KR 400/500/700 파일이 등록되어 있습니다.
- 모바일 앱의 내부 글꼴명은 스크린샷만으로 확정하지 않았습니다. 공개 PC 앱의 글꼴과 제공된 모바일 화면을 구현 기준으로 삼았습니다.

## 원본과 라이선스

- [Google Fonts: Noto Sans KR](https://fonts.google.com/noto/specimen/Noto+Sans+KR)
- [공식 CSS 응답](https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;600;700&display=swap), User-Agent `CHaengim-fonts`, 2026-11-17 조회. 응답의 `fonts.gstatic.com/s/notosanskr/v40/` TTF를 원본 그대로 저장했습니다.
- 라이선스: SIL Open Font License 1.1. Google Fonts 저장소의 [OFL.txt](https://github.com/google/fonts/blob/7af0d90b4d532ffa4b041937b560c6df4e7b1e95/ofl/notosanskr/OFL.txt)를 [notosanskr/OFL.txt](notosanskr/OFL.txt)에 그대로 포함합니다.
- 저작권: Copyright 2014–2021 Adobe, Reserved Font Name `Source`. 자세한 조건은 동봉 라이선스를 참고하세요.

## 다운로드 검증 (2026-11-17)

| 파일 | SHA-256 |
| --- | --- |
| NotoSansKR-Regular.ttf | `84e2b8acadd0a01af9f0de6b0a2d29117fb5b0eabd7c2f8353d9d2da0461d5fa` |
| NotoSansKR-Medium.ttf | `19681f357cdd490191a8eedb5fa824b99979d039143966ed73f4aab1dc1385d1` |
| NotoSansKR-SemiBold.ttf | `b863749bdd69ab2aa2f4c98d83d71933c605b394002b15405d2a42b5e413360e` |
| NotoSansKR-Bold.ttf | `7c81aeacbc15d1a18de6928dddf66cf272fa1dcc401715cfd8325def9390533f` |

라이선스는 앱의 마이 → 오픈소스 라이선스에서도 열 수 있습니다. Android 홈 화면 위젯은 기기 시스템 글꼴을 사용합니다.
