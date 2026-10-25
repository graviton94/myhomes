# 서명 키

| 키 | 파일 | 잠금 암호 (GitHub Secrets 에만) | 쓰는 곳 |
|---|---|---|---|
| 시험용 (sideload) | `sideload.jks.gpg` | `SIDELOAD_PASSPHRASE` | `app.yml` 의 시험용 APK |
| Play 업로드 (upload) | `upload.jks.gpg` | `ANDROID_UPLOAD_PASSPHRASE` | 스토어용 AAB (4단계 `aab.yml`) |

- 키는 `Android signing key (one time)` 워크플로(`android-signing-key.yml`)가 GitHub 안에서 만들고, 암호로 잠근 파일만 저장소에 올린다. 잠그지 않은 키 · 암호는 저장소 · 채팅 · 로그 어디에도 남지 않는다. 로그에는 인증서 지문(SHA-1 · SHA-256)만 찍힌다.
- 키스토어 암호 = 키 암호 = 잠금 암호. 별칭은 `sideload` / `upload`.
- 암호를 잃어버리면 키를 다시 만들어야 한다(`replace` 켜고 실행). 시험용 키가 바뀌면 시험 폰은 한 번 지우고 다시 설치한다.

## 예전 시험 키

`sideload.jks` (암호 `android`) 는 비밀이 아닌 채로 저장소에 올라가 있던 키다. `sideload.jks.gpg` 가 생기기 전까지만 `app.yml` 이 이 키로 서명하고, 그 뒤에는 쓰지 않는다 (잠긴 키가 생기면 지운다).
