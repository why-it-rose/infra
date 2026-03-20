#!/bin/bash
# setup-ec2.sh
# Ubuntu EC2 초기 설정 스크립트
# 실행: bash setup-ec2.sh
#
# 실행 후 수동으로 해야 할 것:
#   1. ~/wir/infra/docker-compose/.env.jenkins 파일 생성 (아래 안내 참고)
#   2. Jenkins UI(http://{IP}:8090)에서 EC2_SSH_KEY Credential 등록
#
set -euo pipefail

INFRA_REPO_URL="https://github.com/why-it-rose/infra.git"
WIR_DIR="$HOME/wir"

echo "=== [1/7] 패키지 목록 업데이트 ==="
sudo apt-get update -y

echo "=== [2/7] Docker 설치 ==="
sudo apt-get install -y ca-certificates curl gnupg lsb-release

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "=== [3/7] Docker 서비스 시작 및 부팅 시 자동 시작 설정 ==="
sudo systemctl enable docker
sudo systemctl start docker

echo "=== [4/7] ubuntu 유저를 docker 그룹에 추가 ==="
sudo usermod -aG docker ubuntu

echo "=== [5/7] git 설치 ==="
sudo apt-get install -y git

echo "=== [6/7] 배포 디렉토리 설정 및 infra repo 클론 ==="
mkdir -p "$WIR_DIR"
cd "$WIR_DIR"

if [ ! -d "infra/.git" ]; then
    git clone "$INFRA_REPO_URL" infra
    echo "infra repo 클론 완료: $WIR_DIR/infra"
else
    echo "infra repo 이미 존재, 클론 생략"
fi

echo "=== [7/7] Jenkins 컨테이너 빌드 및 시작 ==="
cd "$WIR_DIR/infra/docker-compose"

if [ ! -f ".env.jenkins" ]; then
    echo ""
    echo "⚠️  .env.jenkins 파일이 없어 Jenkins를 시작할 수 없습니다."
    echo "   아래 내용으로 $WIR_DIR/infra/docker-compose/.env.jenkins 파일을 생성하세요:"
    echo ""
    echo "   EC2_HOST_DEV=<dev EC2 IP>"
    echo "   EC2_HOST_PROD=<prod EC2 IP>"
    echo "   SLACK_WEBHOOK_URL=<Slack Webhook URL>"
    echo ""
    echo "   생성 후 아래 명령어로 Jenkins를 시작하세요:"
    echo "   cd $WIR_DIR/infra/docker-compose"
    echo "   docker compose -f docker-compose.jenkins.yml up -d --build"
else
    docker compose -f docker-compose.jenkins.yml up -d --build
    echo "Jenkins 시작 완료: http://\$(curl -s ifconfig.me):8090"
fi

echo ""
echo "=== 설치 완료 ==="
echo ""
echo "⚠️  서비스 배포용 환경변수 파일도 생성 필요:"
echo "   $WIR_DIR/infra/docker-compose/.env.dev"
echo "   $WIR_DIR/infra/docker-compose/.env.prod"
echo ""
echo "⚠️  Jenkins 시작 후 UI에서 EC2_SSH_KEY Credential 수동 등록 필요"
echo "   Manage Jenkins → Credentials → SSH Username with private key"
echo ""
echo "⚠️  docker 그룹 적용을 위해 재로그인 또는 'newgrp docker' 실행 필요"
echo ""
echo "✅ EC2 초기 설정 완료"
