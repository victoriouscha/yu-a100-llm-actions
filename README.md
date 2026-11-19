# RunPod A100 LLM 실습 공통 Docker 이미지 (초안 1.0)

A100 80GB Pod **10대**, 각 Pod에 학생 **4명**이 접속하는 대학 GPU 실습용 공통 환경입니다.
**GitHub Actions에서 빌드**하므로 Windows에 Docker Desktop/WSL2를 설치할 필요가 없습니다.

## 이미지 구성

- Ubuntu 24.04 / Python 3.12 / NVIDIA CUDA 12.9.1 cuDNN Runtime
- PyTorch 2.8.0 (cu129), Transformers 5.23.0, Accelerate 1.16.0, bitsandbytes 0.50.2, ipykernel 7.4.0
- VS Code Remote SSH 대상 학생 계정: `student01` ~ `student04`
- 모델 가중치는 **이미지에 넣지 않습니다**: RunPod 저장소 `/workspace/hf-cache/hub`에 별도 관리
- 학생 홈 폴더: `/home/studentXX` → `/workspace/students/studentXX`
- SSH는 공개키 인증 전용이며 개인키/비밀번호는 GitHub와 이미지에 넣지 않습니다.

## 1. GitHub Actions에서 이미지 빌드만 시험하기 (Docker Hub 계정 불필요)

- `Dockerfile`, `requirements.txt`, `start.sh`, 빌드 워크플로를 `main`에 수정하면 **빌드만 자동 시험**합니다. Docker Hub에는 업로드하지 않습니다.

1. [Actions / Build and publish RunPod LLM image](https://github.com/victoriouscha/yu-a100-llm-actions/actions/workflows/docker-build.yml) 페이지를 엽니다.
2. `Run workflow`를 누르고 `Publish image to Docker Hub` 체크를 **해제**한 상태로 실행합니다.
3. 빌드가 성공하면 `Dockerfile`의 패키지 설치 단계가 정상 수행된 것입니다.
4. 이 모드는 이미지를 Docker Hub에 업로드하지 않습니다. GitHub 일반 runner에는 GPU가 없으므로 실제 CUDA 테스트도 수행하지 않습니다.

## 2. Docker Hub에 배포하기 (계정 소유자가 직접 수행할 보안 단계)

1. [Docker Hub](https://hub.docker.com/)에 로그인하거나 계정을 만듭니다. **GitHub 사용자명과 Docker Hub 사용자명은 같지 않아도 됩니다.**
2. Docker Hub에서 `yu-a100-llm` 저장소를 생성합니다. 10대 RunPod에서 인증 없이 가져오기 편하도록 **Public**을 권장하며, 내부 자료를 이미지에 넣는다면 별도 보안 설계를 하세요.
3. Docker Hub → Account settings → Personal access tokens에서 **Repo Read & Write** 권한 토큰을 발급합니다. 비밀번호 대신 토큰을 사용합니다.
4. [GitHub Actions Secrets 설정](https://github.com/victoriouscha/yu-a100-llm-actions/settings/secrets/actions)에서 `New repository secret`으로 아래 두 값을 각각 저장합니다.
   - `DOCKERHUB_USERNAME`: Docker Hub 사용자 이름 (GitHub ID가 아니라 Docker Hub ID)
   - `DOCKERHUB_TOKEN`: Docker Hub에서 발급한 PAT 토큰
5. 같은 [GitHub Actions 페이지](https://github.com/victoriouscha/yu-a100-llm-actions/actions/workflows/docker-build.yml)에서 `Run workflow` → **Publish image to Docker Hub 체크** → 실행합니다.
6. 성공하면 `<DOCKERHUB_USERNAME>/yu-a100-llm:1.0` 이미지가 Docker Hub에 게시됩니다. 이미지 용량이 커 빌드 오류가 발생할 수 있으므로 Actions 로그의 마지막 오류를 확인합니다.

**중요:** Docker Hub 토큰, SSH 개인키, 학생 Hugging Face 토큰은 채팅·GitHub 파일·Docker 이미지에 기록하지 마세요.

## 3. RunPod A100 한 대에서 먼저 시험하기

- RunPod Pod 생성 시 Container Image를 `<DOCKERHUB_USERNAME>/yu-a100-llm:1.0`로 설정
- SSH TCP 포트 `22`를 노출하고, RunPod 접속 화면의 실제 SSH 호스트/포트 사용
- Pod 환경변수 `PUBLIC_KEY` 또는 `SSH_PUBLIC_KEY`에 관리자 SSH **공개키** 등록
- 학생 4명 공개키는 각각 `STUDENT01_PUBKEY` ~ `STUDENT04_PUBKEY`에 별도 등록
- `/workspace` 저장소 마운트·영속성은 RunPod Pod/볼륨 설정에서 반드시 별도 검증
- GPU 정상 인식 시험:
  ```bash
  python --version
  python -c "import torch; print(torch.__version__, torch.version.cuda, torch.cuda.is_available()); print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'NO_GPU')"
  python -c "import transformers, accelerate, bitsandbytes; print(transformers.__version__, accelerate.__version__, bitsandbytes.__version__)"
  ```
- 이후 Qwen3-8B 4-bit NF4 및 Gemma 3 4B-IT를 강사 계정에서 실제 로드·비교 검증
- 1대에서 SSH 접속, GPU 추론, 학생 폴더 권한을 확인한 후 동일 이미지를 10대로 확장합니다.

## 주의사항

- GitHub 기본 Ubuntu runner는 디스크 약 14GB이며 CUDA/PyTorch 이미지 빌드가 공간 부족으로 실패할 수 있습니다. 워크플로는 기본 정리를 수행하나 실제 성공을 보장하지 않습니다.
- GitHub Actions 빌드 성공은 패키지 설치 성공이지 RunPod GPU 추론 검증 완료를 의미하지 않습니다.
- Gemma 3 접근 승인 및 Hugging Face 인증은 각 Pod에서 별도로 수행합니다. `HF_HOME`을 공유 폴더로 설정하지 않습니다.
- `/workspace`를 영구 볼륨으로 사용할 경우 기존 파일의 소유권과 권한을 확인합니다.
- 학생 결과는 GitHub 포트폴리오 등 별도 위치에 제출해야 합니다.
