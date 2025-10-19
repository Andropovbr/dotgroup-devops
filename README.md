# DevOps Challenge — PHP App (Docker + CI + Terraform + Kubernetes)

Este repositório entrega as etapas solicitadas no teste técnico (containerização, CI, IaC e estratégia de observabilidade) para uma aplicação PHP simples. O escopo e os artefatos foram estruturados conforme o enunciado do desafio【7†Teste Técnico - Analista DevOps】.

## Estrutura
```
.
├── Dockerfile
├── .github/
│   └── workflows/
│       └── main.yml
├── k8s/
│   ├── deployment.yaml
│   └── service.yaml
└── terraform/
    ├── versions.tf
    ├── providers.tf
    ├── variables.tf
    ├── vpc.tf
    └── eks.tf
```

---

## Etapa 1 — Containerização (Dockerfile)
- Base: `php:8.2-apache` (imagem oficial, estável e com Apache embutido).
- Multi-stage build (builder + runtime) para isolar dependências e reduzir a superfície de ataque.
- Usuário não-root (`www-data`) no runtime.
- Hardening básico do Apache (oculta assinatura e tokens de versão).

Caso a aplicação use Composer, basta descomentar as linhas de instalação no `Dockerfile`.

---

## Etapa 2 — Integração Contínua (GitHub Actions)
Pipeline em `.github/workflows/main.yml`:
1. Checkout
2. Build Docker com Buildx
3. Scan de vulnerabilidades com Trivy (não falha o job por padrão; ajuste `exit-code` se quiser gatear o deploy)
4. Push da imagem para Docker Hub (tags: `latest`, branch e SHA)

**Configuração necessária (Secrets do repositório):**
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

**Personalize** o `image` em `k8s/deployment.yaml` para `DOCKERHUB_USERNAME/php-app:latest`.

---

## Etapa 3 — IaC (Terraform) + Deploy (Kubernetes)
A infraestrutura usa **AWS + EKS** (padrão de mercado, flexível, excelente integração com ecossistema CNCF). O Terraform cria:
- **VPC (pública e privada, NAT Gateway)** — módulo `terraform-aws-modules/vpc`.
- **Cluster EKS 1.29** com node group gerenciado — módulo `terraform-aws-modules/eks`.

### Passos para provisionar
```bash
cd terraform
terraform init
terraform apply -auto-approve
```

Após o apply, configure o kubeconfig (usando AWS CLI):
```bash
aws eks --region $(terraform output -raw cluster_name | sed 's/.*/us-east-1/') update-kubeconfig --name devops-challenge-eks
```
> Ajuste a região se necessário (`var.aws_region`).

### Deploy dos manifests
```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl get svc php-app-svc -w
```
O `Service` é `LoadBalancer`, expondo HTTP na porta 80.

### Como estender para CD
Existem duas abordagens:
1. **Kubectl no GitHub Actions:** após a etapa de push da imagem, autenticar no cluster (IAM OIDC + kubeconfig) e rodar:
   ```yaml
   - name: Deploy to EKS
     uses: azure/k8s-deploy@v5
     with:
       manifests: |
         k8s/deployment.yaml
         k8s/service.yaml
       images: |
         ${{ secrets.DOCKERHUB_USERNAME }}/php-app:latest
   ```
   Ou um `kubectl rollout restart deployment/php-app` após atualizar a imagem via patch.

2. **GitOps (recomendado):** usar **Argo CD** ou **Flux** apontando para este repositório. Um commit que atualiza a tag da imagem desencadeia a reconciliação e o rollout no cluster.

**Por que EKS (vs. ECS/Fargate)?**
- Padrão CNCF, portabilidade, facilidade para acoplar observabilidade (Prometheus/Grafana/Loki), service mesh, ingress controllers e escalabilidade nativa de workloads variados. Para times que buscam maturidade DevOps e autonomia dos squads, EKS tende a ser vantajoso.

---

## Etapa 4 — Observabilidade (descrição)
**Stack sugerida:**
- **Prometheus** + **Grafana** para métricas e dashboards.
- **Loki** para logs centralizados (com Promtail).
- **Alertmanager** para alertas baseados em SLOs.

**3 métricas essenciais do dashboard de saúde:**
1. **Taxa de erro (5xx / total de reqs)** — disponibilidade percebida.
2. **Latência p95/p99** — experiência do usuário sob pico.
3. **Uso de CPU/Memória por pod** — capacidade e saturação.

**Extras úteis:**
- **HPA** (Horizontal Pod Autoscaler) baseado em CPU/memória ou métricas customizadas (RPS/latência).
- **Ingress + TLS** (ALB Ingress Controller no EKS ou Nginx Ingress).

---

## Notas finais
- Alinhei a entrega às etapas e expectativas do enunciado (Dockerfile otimizado e seguro, CI com scan + push, IaC para EKS e manifestos K8s), conforme solicitado【7†Teste Técnico - Analista DevOps】.
- Para simplificar a avaliação, usei módulos oficiais de VPC/EKS e deixei variáveis com defaults.

## Próximos passos (opcionais)
- Adicionar pipeline de **CD** (kubectl ou GitOps).
- Habilitar **ECR** (em vez de Docker Hub) e usar OIDC do GitHub para push sem secrets.
- Adicionar **Ingress** e **cert-manager** para HTTPS.
