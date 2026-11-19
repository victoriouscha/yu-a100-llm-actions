# RunPod A100 LLM 실습 공통 Docker 이미지 (초안 1.0)

- 대상: A100 80GB Pod 10대, 각 Pod 학생 4명
- OS: Ubuntu 24.04 / Python 3.12 / CUDA runtime 12.9.1 / PyTorch 2.8.0 (cu129)
- 패키지: Transformers 5.23.0, Accelerate 1.16.0, bitsandbytes 0.50.2, ipykernel 7.4.0
- VS Code Remote SSH 접속 대상: student01~student04
- 저장: /home/studentXX → /workspace/students/studentXX (Pod 볼륨에 저장)
- 모델 파일: /workspace/hf-cache/hub (Docker 이미지 외부)
- SSH: 비밀번호 로그인 비활성화, 공개키 인증 전용

## GitHub Actions 실행

1. GitHub에서 `yu-a100-llm-actions`라는 저장소를 만듭니다.
2. 이 압축 파일을 해제하고 내부의 파일/폴더를 GitHub 저장소 최상위에 업로드합니다.
3. Docker Hub에서 개인 액세스 토큰(PAT)을 발급하되 이미지 push에 필요한 Repo Read/Write 권한을 부여합니다.
4. GitHub 저장소 → Settings → Secrets and variables → Actions → New repository secret:
   - `DOCKERHUB_USERNAME`: Docker Hub 사용자명 (비밀번호 아님)
   - `DOCKERHUB_TOKEN`: 위에서 발급한 PAT (채팅/코드/README에 작성 금지)
5. 저장소 → Actions → `Build and publish RunPod LLM image` → Run workflow.
6. 빌드 성공 시 Docker Hub에 `<DockerHub사용자명>/yu-a100-llm:1.0` 이미지가 생성됩니다.
7. RunPod에서 단일 Pod로 먼저 시험한 뒤 10대에 적용합니다.

## RunPod 첫 시험

- Template image: `<DockerHub사용자명>/yu-a100-llm:1.0`
- Expose TCP port: `22/tcp`
- Admin SSH 공개키: RunPod Pod env `PUBLIC_KEY` 또는 `SSH_PUBLIC_KEY`
- 학생 각 공개키: 각 Pod env `STUDENT01_PUBKEY` ~ `STUDENT04_PUBKEY`
- 실제 학생 공개키는 GitHub에 올리거나 이미지에 포함하지 마세요.
- 다른 Pod에서도 학생 이름은 student01~student04를 반복 사용하지만, 각 Pod에 서로 다른 학생 공개키를 넣습니다.
- Pod에서 접속 후: `python --version`, `python -c "import torch; print(torch.__version__, torch.version.cuda, torch.cuda.is_available())"`

## 중요한 제약

- GitHub 기본 runner에서는 GPU 테스트가 불가능하므로, Docker 이미지의 CUDA 실제 실행 여부는 RunPod A100에서 확인합니다.
- CUDA/PyTorch 이미지가 커서 GitHub 기본 runner 저장공간 부족으로 빌드가 실패할 수 있습니다. 이 경우 로그의 `no space left on device`를 확인해 빌드 전략을 조정해야 합니다.
- Gemma 3 모델의 사용 승인 및 Hugging Face 인증은 각 Pod에서 별도로 수행합니다. HF_HOME은 공유 폴더로 지정하지 않습니다.
- /workspace 저장의 영속성은 RunPod Pod/볼륨 유형과 종료 방식에 따라 달라집니다. 학생은 결과를 GitHub에 추가 제출해야 합니다.
- RunPod에서 초기 이미지 기동이 성공했더라도, 학생 공개키, 패키지 충돌, 모델 로딩 및 양자화 검증이 끝나기 전까지는 교육 배포 확정으로 간주하지 않습니다.
- 교육 중 SSH 키 관리와 계정별 접근 권한을 반드시 사전 시험하세요.
