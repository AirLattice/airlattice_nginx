# Nginx 기능정의서 (airlattice)

## 1. 목적
- ai.airlattice.com, cash.airlattice.com 도메인을 HTTPS로 제공하고, 내부 앱으로 안전하게 프록시한다.
- Let’s Encrypt 인증서를 자동 갱신한다.

## 2. 범위
- 대상 도메인: ai.airlattice.com, cash.airlattice.com
- 백엔드 서비스:
  - ai.airlattice.com -> opengpts-frontend:5173
  - cash.airlattice.com -> cashflow-api:8080
- 인프라 구성: Docker Compose 기반 nginx + certbot

## 3. 전제 조건
- DNS A/AAAA 레코드가 서버 공인 IP로 연결됨.
- 인바운드 포트 80/443이 외부에 개방됨.
- 앱 컨테이너가 동일 네트워크(`nginx-net`)에 연결되어 있고, 서비스 이름으로 접근 가능함.

## 4. 주요 기능
### 4.1 HTTP -> HTTPS 리다이렉트
- 80 포트로 들어온 요청은 HTTPS로 301 리다이렉트한다.
- 예외: `/.well-known/acme-challenge/` 경로는 인증서 발급을 위해 HTTP로 제공한다.

### 4.2 TLS 종단(SSL Termination)
- nginx가 TLS를 종단하고, 내부 통신은 HTTP로 처리한다.
- 인증서는 Let’s Encrypt에서 발급된 파일을 사용한다.

### 4.3 리버스 프록시
- ai.airlattice.com 요청을 `opengpts-frontend:5173`로 프록시한다.
- cash.airlattice.com 요청을 `cashflow-api:8080`으로 프록시한다.

### 4.4 WebSocket 지원
- ai.airlattice.com 프록시는 `Upgrade`/`Connection` 헤더를 전달해 WebSocket을 지원한다.

### 4.5 표준 프록시 헤더 전달
- `Host`, `X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Proto`를 전달한다.

## 5. 인증서 발급/갱신
- 초기 발급: `scripts/init-certbot.sh` 실행.
- 자동 갱신: certbot 컨테이너가 12시간마다 갱신을 시도한다.

## 6. 운영/모니터링
- nginx 상태 확인: `docker ps`, `docker logs airlattice-nginx`
- 인증서 로그: certbot 컨테이너 로그 및 `/var/log/letsencrypt/letsencrypt.log`

## 7. 보안 요구사항
- 80/443 외 불필요 포트 노출 금지.
- 인증서/개인키는 Git에 커밋하지 않는다.

## 8. 구성요소 요약
- nginx 컨테이너: reverse proxy + TLS
- certbot 컨테이너: 인증서 발급/자동 갱신
- 외부 네트워크: `nginx-net`

## 9. 장애 대응
- 80/443 차단 시 인증서 발급 실패.
- DNS 미설정/NXDOMAIN 시 인증서 발급 실패.
- 인증서 경로 불일치 시 nginx 기동 실패.
