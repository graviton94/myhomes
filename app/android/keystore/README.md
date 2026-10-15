# 서명 키

- `sideload.jks`: 폰에 직접 설치하는 시험용 키 (암호 `android`, 별칭 `sideload`). 비밀이 아니라서 저장소에 둔다.
  모든 CI 빌드가 같은 서명을 가져서 새 APK 가 기존 설치 위에 덮어 설치된다.
- `upload.jks.gpg`: Play 스토어 올리기 키. 4단계에서 `signing-key.yml` 로 GitHub 안에서 만들고 `ANDROID_UPLOAD_PASSPHRASE` 로 잠근다 (아직 없음).
- 스토어 설치본과 시험 APK 는 서명이 달라서 서로 덮어 설치되지 않는다 (지우고 설치).
