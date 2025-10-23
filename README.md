# Desafio DevOps – DOT Group

Este repositório contém a infraestrutura e os artefatos para implantação de uma aplicação PHP simples em um cluster **Amazon EKS** utilizando infraestrutura como código Terraform, CI/CD com GitHub Actions e pipeline de segurança com Trivy.

> **Observação importante:** o desafio técnico original menciona uma “Aplicação Exemplo” em PHP a ser fornecida. Como o link não foi incluído no material recebido, utilizei temporariamente um `index.php` de teste (“Hello World”) para estruturar o ambiente. Assim que a aplicação oficial for disponibilizada, bastará substituir os arquivos na pasta `app/` e gerar uma nova imagem Docker.

---

## Arquitetura

- **Linguagem/Runtime**: PHP + Apache (porta 8080 no container)
- **Container Registry**: Docker Hub (`andropovbr/php-app`)
- **Orquestração**: Amazon EKS
- **Infraestrutura como Código**: Terraform
- **Observabilidade**:
  - **Logs**: integrados com Amazon CloudWatch
  - **Probes**: readiness/liveness configuradas no deployment para monitorar saúde da aplicação
- **CI/CD**: GitHub Actions
  - Build e push da imagem
  - Scan de vulnerabilidades com Trivy
  - Deploy automatizado no cluster EKS

---

## Build da Imagem

Antes de rodar o pipeline, é possível testar localmente:

```bash
# build local
docker build -t andropovbr/php-app:latest .

# testar localmente
docker run -p 8080:8080 andropovbr/php-app:latest

# acessar
curl http://localhost:8080
```

---

## Deploy no EKS

1. Aplicar a infraestrutura com Terraform:

```bash
terraform init
terraform plan
terraform apply
```

2. Configurar acesso ao cluster:

```bash
aws eks update-kubeconfig --region us-east-1 --name dotgroup-devops-eks
```

3. Implantar os manifests Kubernetes:

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

4. Acompanhar status dos pods:

```bash
kubectl get pods -w
kubectl logs <pod-name> -c php-app
```

---

## Testando a Aplicação

Recupere o DNS público do LoadBalancer:

```bash
kubectl get svc
```

Exemplo de saída:

```
php-app-svc   LoadBalancer   172.20.x.x   a51f596ba2cc44763b2c1b6fb15da935-20565008.us-east-1.elb.amazonaws.com   80:31389/TCP
```

Teste a aplicação:

```bash
APP_URL="http://a51f596ba2cc44763b2c1b6fb15da935-20565008.us-east-1.elb.amazonaws.com"
curl -I $APP_URL
curl $APP_URL/index.php
```

Saída esperada:
```
HTTP/1.1 200 OK
Hello world!
```

---

## Observabilidade e Segurança

- **Readiness & Liveness Probes** garantem que apenas pods saudáveis recebam tráfego.  
- **Trivy** roda no pipeline para escanear vulnerabilidades na imagem Docker.  
- **CloudWatch Logs** centraliza os logs dos containers em tempo real.  
- **Kubernetes Rollout** garante atualizações sem downtime.

---

## Próximos passos

- Substituir `index.php` pelo código oficial da aplicação fornecida no desafio.
- Ajustar pipeline para refletir qualquer dependência adicional da app.
- (Opcional) Integrar monitoramento mais avançado (Prometheus/Grafana, OpenTelemetry).

---

## Implantação Contínua (CD)

Atualmente, o pipeline está configurado para buildar, escanear e publicar a imagem Docker a cada `push` na branch `main`.  
Para evoluí-lo para um **pipeline de CD (Continuous Deployment)**, bastaria adicionar uma etapa extra ao final do workflow:

1. **Autenticação no cluster EKS**:  
   Utilizar credenciais configuradas no repositório (ex.: `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY`) para permitir que a GitHub Action execute `kubectl` contra o cluster.

2. **Atualização do deployment no Kubernetes**:  
   Rodar um comando que atualiza a imagem no deployment e faz o rollout automático:
   ```yaml
   - name: Deploy to EKS
     run: |
       aws eks update-kubeconfig --region us-east-1 --name dotgroup-devops-eks
       kubectl set image deployment/php-app php-app=andropovbr/php-app:latest
       kubectl rollout status deployment/php-app

---

## Autor

**André Santos**  
- GitHub: [@andropovbr](https://github.com/andropovbr)  
- Docker Hub: [andropovbr/php-app](https://hub.docker.com/r/andropovbr/php-app)  
- Infraestrutura e CI/CD desenvolvidos para desafio técnico DOT Group.
