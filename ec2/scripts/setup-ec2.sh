#!/bin/bash
# setup-ec2.sh
# Ubuntu EC2 초기 설정 스크립트
# 실행: bash setup-ec2.sh
#
# 실행 후 배포에 필요한 파일:
#   ~/wir/infra/docker-compose/.env.dev   ← DB URL, 비밀번호 등 환경변수
#   ~/wir/infra/docker-compose/.env.prod  ← (prod EC2 한정)
#
set -euo pipefail

INFRA_REPO_URL="https://github.com/<org>/infra.git"   # TODO: 실제 org 이름으로 교체
WIR_DIR="$HOME/wir"

echo "=== [1/6] 패키지 목록 업데이트 ==="
sudo apt-get update -y

echo "=== [2/6] Docker 설치 ==="
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

echo "=== [3/6] Docker 서비스 시작 및 부팅 시 자동 시작 설정 ==="
sudo systemctl enable docker
sudo systemctl start docker

echo "=== [4/6] ubuntu 유저를 docker 그룹에 추가 ==="
sudo usermod -aG docker ubuntu

echo "=== [5/6] git 설치 ==="
sudo apt-get install -y git

echo "=== [6/6] 배포 디렉토리 설정 및 infra repo 클론 ==="
mkdir -p "$WIR_DIR"
cd "$WIR_DIR"

if [ ! -d "infra/.git" ]; then
    git clone "$INFRA_REPO_URL" infra
    echo "infra repo 클론 완료: $WIR_DIR/infra"
else
    echo "infra repo 이미 존재, 클론 생략"
fi

echo ""
echo "=== 설치 완료 ==="
echo ""
echo "⚠️  다음 환경변수 파일을 직접 생성해야 합니다 (절대 Git에 커밋하지 마세요):"
echo "   $WIR_DIR/infra/docker-compose/.env.dev"
echo "   $WIR_DIR/infra/docker-compose/.env.prod"
echo ""
echo "   파일 예시:"
echo "   DOCKERHUB_USERNAME=myusername"
echo "   SPRING_DATASOURCE_URL=jdbc:mysql://..."
echo "   SPRING_DATASOURCE_PASSWORD=..."
echo ""
echo "⚠️  docker 그룹 적용을 위해 재로그인 또는 'newgrp docker' 실행 필요"
echo ""
echo "✅ EC2 초기 설정 완료"
