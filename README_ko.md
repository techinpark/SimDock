# SimDock

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-blue" alt="Platform">
  <img src="https://img.shields.io/badge/swift-5.9-orange" alt="Swift">
  <img src="https://img.shields.io/github/license/techinpark/SimDock" alt="License">
  <img src="https://img.shields.io/github/v/release/techinpark/SimDock" alt="Release">
</p>

<p align="center">
  <a href="README.md">English</a>
</p>

**SimDock**은 macOS 메뉴바에서 iOS 시뮬레이터를 빠르게 실행하고 관리할 수 있는 경량 유틸리티 앱입니다.

## 주요 기능

- **메뉴바에서 바로 실행** — 시뮬레이터 목록을 확인하고 클릭 한 번으로 부팅
- **런타임별 그룹핑** — iOS 26, iOS 18 등 런타임별로 정리된 목록
- **상태 표시** — 실행 중 / 종료 상태를 직관적인 컬러 인디케이터로 표시
- **데이터 디렉토리 탐색** — 마우스 오버 시 시뮬레이터 내부 폴더를 바로 확인
- **Finder 연동** — 서브메뉴에서 클릭하면 해당 폴더를 Finder에서 열기

## 설치 방법

### Homebrew (권장)

```bash
brew install --cask simdock
```

### GitHub Releases

[Releases](https://github.com/techinpark/SimDock/releases) 페이지에서 최신 `.dmg` 파일을 다운로드하여 설치할 수 있습니다.

1. `SimDock.dmg` 다운로드
2. DMG 파일 열기
3. `SimDock.app`을 `/Applications` 폴더로 드래그

### Mac App Store

<a href="#">
  <img src="https://developer.apple.com/app-store/marketing/guidelines/images/badge-download-on-the-mac-app-store.svg" alt="Download on the Mac App Store" height="40">
</a>

> 출시 예정

## 요구 사항

- macOS 13.0 (Ventura) 이상
- Xcode Command Line Tools (`xcode-select --install`)

## 소스에서 빌드

```bash
git clone https://github.com/techinpark/SimDock.git
cd SimDock
xcodegen generate
xcodebuild -scheme SimDock -configuration Release build
```

또는 Xcode에서 직접 열어 빌드할 수 있습니다.

```bash
open SimDock.xcodeproj
```

## 기여하기

기여는 언제나 환영합니다! 버그 리포트, 기능 제안, PR 모두 감사합니다.

1. 레포지토리를 Fork 합니다
2. Feature 브랜치를 생성합니다 (`git checkout -b feature/amazing-feature`)
3. 변경사항을 커밋합니다 (`git commit -m 'Add amazing feature'`)
4. 브랜치에 Push 합니다 (`git push origin feature/amazing-feature`)
5. Pull Request를 생성합니다

## 라이선스

이 프로젝트는 MIT 라이선스로 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참고하세요.
