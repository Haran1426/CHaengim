# 챙김 앱 아이콘

짙은 숲색 바탕 위에 크림색 준비물 파우치, 체크 표시와 연두색 문서 탭을 사용합니다. 앱의 숲 테마 색상과 맞췄습니다.

- `launcher-foreground.png`: 내장 image_gen 도구로 생성한 원본. 투명 여백을 포함합니다.
- `launcher-icon.png`: 512px 정사각형 아이콘.
- `launcher-preview.png`: 원형·둥근 사각형·48px 크기 검수 이미지.
- Android 8 이상에서는 배경과 전경을 분리한 adaptive icon을 사용합니다. 이전 버전용 PNG도 각 밀도로 제공합니다.
- 웹 아이콘·favicon과 Windows ICO에도 같은 그림을 사용합니다.

## 재생성

Python 3와 Pillow가 필요합니다.

```sh
python -m pip install Pillow
python tool/generate_launcher_icons.py
```

이 스크립트는 승인한 원본을 크기별로 내보냅니다. 아이콘을 변경하려면 원본을 교체한 후 실행합니다. `assets/branding`은 제작용 원본이며 Flutter 런타임 자산 목록에 추가하지 않습니다.

기준: [Android adaptive icon 안내](https://developer.android.com/develop/ui/views/launch/icon_design_adaptive).

## 생성 방식과 프롬프트

내장 image_gen 도구를 사용했습니다. CLI/API 방식은 사용하지 않았습니다.

Use case: logo-brand. Create one final production app icon FOREGROUND asset for a Korean personal deadline and preparation checklist app named Chaengim (챙김). Transparent background, square 1024x1024 image. Design: a single warm ivory (#F6F4EF) soft rectangular organizer pouch with a gently curved open top and short rounded carry loop, suggesting carefully packed essentials; a bold simple deep forest green (#244C3F) checkmark on the front, with one tiny pale lime (#E0EEAC) document tab peeking out at top right. Beautiful minimal flat vector-like geometry with slightly friendly rounded corners, mature editorial Korean productivity app brand, high contrast and immediately legible at 48px. The pouch is the only motif, no text, no lettering, no wordmark, no borders, no sparkles, no faces, no tiny decorative details, no gradient, no photorealism, no texture, no cast shadow. Frontal view, perfectly centered, balanced. Important Android adaptive icon constraint: ALL artwork including handle and document tab must fit inside the central 58% width and 58% height of the image; generous truly transparent margin on every side. This image will be placed over a solid dark forest green background by the app. Do not draw the background or an outer app-icon tile. Deliver a clean polished transparent PNG foreground, not a mockup or presentation.

