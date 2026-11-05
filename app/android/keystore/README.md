# 서명 키

| 키 | 파일 | 잠금 암호 (GitHub Secrets 에만) | 쓰는 곳 |
|---|---|---|---|
| 시험용 (sideload) | `sideload.jks.gpg` | `SIDELOAD_PASSPHRASE` | `app.yml` 의 시험용 APK |
| Play 업로드 (upload) | `upload.jks.gpg` | `ANDROID_UPLOAD_PASSPHRASE` | 스토어용 AAB (4단계 `aab.yml`) |

- 키는 `Android signing key (one time)` 워크플로(`android-signing-key.yml`)가 GitHub 안에서 만들고, 암호로 잠근 파일만 저장소에 올린다. 잠그지 않은 키 · 암호는 저장소 · 채팅 · 로그 어디에도 남지 않는다. 로그에는 인증서 지문(SHA-1 · SHA-256)만 찍힌다.
- 키스토어 암호 = 키 암호 = 잠금 암호. 별칭은 `sideload` / `upload`.
- 암호를 잃어버리면 키를 다시 만들어야 한다(`replace` 켜고 실행). 시험용 키가 바뀌면 시험 폰은 한 번 지우고 다시 설치한다.

## 지금 키 (2026-10-25 생성)

| 키 | SHA-1 | SHA-256 |
|---|---|---|
| sideload | `63:46:E9:B9:38:99:24:35:40:B0:7C:5A:C3:2D:26:0D:00:EA:31:AE` | `DD:EB:24:AF:D3:86:E6:82:B0:64:BE:4E:0D:77:F6:4E:81:F0:12:64:A4:61:BE:29:30:51:A0:95:C9:B4:3A:CE` |
| upload | `93:26:C3:D9:19:9E:80:9A:3F:12:51:62:F0:56:EB:37:37:6E:42:A3` | `B2:B8:97:9F:CC:67:72:FF:F6:92:CB:85:1E:74:4B:51:E1:23:B0:3F:D1:CE:0C:E8:20:D4:DF:A1:5C:4F:48:B1` |

| Play 앱 서명 (Google 보관) | `9A:79:51:2F:B2:C1:A9:FE:9B:10:64:5E:60:8D:25:22:34:83:2D:09` | 카카오 키 해시 `mnlRL7LBqf6bEGReYI0lIjSDLQk=` (SHA-256 은 Play Console › 앱 무결성) |

Play 에서 받은 앱은 Google 이 앱 서명 키로 다시 서명한다: 이 지문을 Firebase 디지털 지문과 카카오 키 해시에 넣어야 로그인이 된다.

인증서 지문은 공개 값이다. Firebase 프로젝트 설정 → 내 앱 → 디지털 지문에 넣는다 (Google 로그인을 붙일 때).

## 예전 시험 키

예전 `sideload.jks`(암호 `android`)는 저장소 기록에 공개된 채 남아 있어 더 쓰지 않는다. 그 키로 설치한 시험 앱은 한 번 지우고 새 APK 를 설치한다.
