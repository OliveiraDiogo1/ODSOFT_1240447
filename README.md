# projeto_odsoft_1240447

Projeto 1 da unidade curricular de Organização do Desenvolvimento de Software
(ODSOFT), 2026-2027.

O ponto de partida é o serviço REST de gestão de biblioteca desenvolvido em
PSOFT (`psoft-project-2024-g1`). Este repositório é independente do projeto de
ARQSOFT: o código base é o mesmo, mas o âmbito é diferente. O ODSOFT não pede
novas funcionalidades de biblioteca; pede a evolução do processo de build,
testes, integração, entrega e deployment.

Repositório remoto:

```
https://github.com/OliveiraDiogo1/ODSOFT_1240447
```

## Estado atual — Fases 1, 2 e 3 (local + VM)

Implementado:

- repositório independente com o baseline do LMS;
- baseline de testes e de build medido e guardado;
- Maven com JaCoCo, Checkstyle, SpotBugs, Maven Enforcer e PIT;
- `Jenkinsfile` declarativo com checkout, build, análise estática, testes,
  testes de sistema, cobertura, mutation testing e packaging;
- Jenkins local em Docker (`jenkins/`);
- relatórios de testes, cobertura, análise estática e mutação arquivados pelo
  pipeline;
- job `odsoft-p1` criado por SCM e build **#4 com sucesso** (102 testes,
  90,4 s), com evidências em `evidence/jenkins/`;
- build **#6 na VM com sucesso**: 116 testes, `Coverage Gate` e `Mutation
  Testing`, commit `75acc4e`, com evidências em `evidence/jenkins-vm/`;
- build **#8 automático via webhook**: “Started by GitHub push”, commit
  `41a3379`, 116 testes, `Coverage Gate` e PIT, com evidências em
  `evidence/jenkins-vm/`;
- deployment local para `dev`, `staging` e `prod` em contentores Docker
  separados, com health checks e evidências em `evidence/deploy/`;
- deployment na VM DEI (`vs264`) com JAR + systemd, validado em `dev`,
  `staging` e `prod`, com health checks públicos e login em staging;
- Jenkins na VM com job `odsoft-p1` por SCM, com build do pipeline concluído;
- 5 testes de sistema com login, pesquisa autenticada e acesso sem token;
- PIT sobre as classes de domínio, com 301 mutantes e 50% mutation score;
- gates de cobertura JaCoCo (linhas 35%, ramos 9%) e PIT (mutação 45%,
  cobertura 65%).

Ainda não implementado:

- relatório final de avaliação antes/depois e rastreabilidade completa (Fase 4).

## Baseline medido

O baseline foi medido antes de acrescentar os plugins de qualidade, para servir
de comparação à rubrica C3.3.

| Indicador | Valor inicial |
|---|---:|
| Testes executados | 102 |
| Falhas | 0 |
| Tempo de `mvn clean test` | 43,4 s |
| Tempo de `mvn -DskipTests package` | 14,5 s |
| Cobertura de linhas | 19,5% (558 de 2 868) |
| Cobertura de ramos | 4,5% (117 de 2 579) |
| Avisos Checkstyle | 109 |
| Avisos SpotBugs | 226 |

Estes valores são o ponto de partida; não são a qualidade final. A Fase 3
melhorou a suite e voltou a medir com as mesmas condições; os resultados estão
na secção seguinte e em `evidence/phase3/`.

Os logs estão em:

```
evidence/baseline/mvn-test.txt
evidence/baseline/mvn-package.txt
evidence/baseline/summary.txt
evidence/baseline/quality-metrics.txt
evidence/baseline/jacoco.csv
```

## Como validar localmente

```bash
mvn -B clean test
mvn -B clean verify
mvn -B -Dtest=SystemTest test
mvn -B org.pitest:pitest-maven:mutationCoverage
mvn -B clean test jacoco:report checkstyle:checkstyle spotbugs:spotbugs
```

Relatórios gerados:

```
target/surefire-reports/
target/site/jacoco/index.html
target/checkstyle-result.xml
target/spotbugsXml.xml
target/*.jar
```

## Jenkins local em Docker

O Jenkins local está preparado em `jenkins/`:

```bash
cd jenkins
docker compose build
docker compose up -d
```

O job `odsoft-p1` já foi criado e executado com sucesso contra o repositório
montado em `/workspace`. O build #4 demorou 90,4 s e produziu os relatórios de
testes, cobertura e Checkstyle. O build #6 foi executado na VM com o pipeline da
Fase 3. As evidências locais estão em:

```
evidence/jenkins/build-summary.txt
evidence/jenkins/build-console.txt
evidence/jenkins/build-api.json
evidence/jenkins/jenkinsfile-validation.txt
evidence/jenkins/version.txt
evidence/jenkins/plugins.txt
```

Abrir:

```
http://localhost:8080
```

Credenciais iniciais do contexto local:

```
utilizador: admin
password: odsoft
```

Estas credenciais são apenas para desenvolvimento local. Devem ser alteradas
antes de qualquer utilização fora da máquina pessoal.

O contentor inclui:

- Jenkins LTS com JDK 17;
- Maven e Git;
- plugins de Git/GitHub, Pipeline, JUnit, JaCoCo, Checkstyle, Warnings NG,
  HTML Publisher, credenciais, timestamps e limpeza de workspace;
- o repositório montado em `/workspace`;
- um utilizador administrador criado por `init.groovy.d/01-security.groovy`.

### Criar o job do pipeline

No Jenkins:

1. **New Item** → **Pipeline** → nome `odsoft-p1`.
2. Em **Pipeline**, escolher **Pipeline script from SCM**.
3. SCM: **Git**.
4. URL:
   - local: `file:///workspace` (o repositório está montado no contentor);
   - GitHub: URL do repositório ODSOFT, quando existir.
5. Branch: `*/main`.
6. Script Path: `Jenkinsfile`.
7. Guardar e executar **Build Now**.

O `Jenkinsfile` também pode ser validado no Jenkins em
**Manage Jenkins → Script Console** ou através do validador de pipeline.

## Pipeline atual

| Stage | Objetivo | Relatórios |
|---|---|---|
| Checkout | Obter o commit e a branch | `GIT_COMMIT`, `GIT_BRANCH` |
| Build | `mvn clean compile` | log Maven |
| Static Analysis | Checkstyle + SpotBugs | XML e HTML |
| Tests | `mvn test` (unitários, integração e sistema) | Surefire XML |
| Coverage | `mvn jacoco:report` | JaCoCo HTML/XML/CSV |
| Coverage Gate | `mvn jacoco:check` | falha se os limites não forem cumpridos |
| Mutation Testing | `mvn pitest:mutationCoverage` | relatório PIT |
| Package | `mvn package` | JAR em `target/` |
| Deploy/Smoke Dev, Staging, Prod | Só com `DEPLOY=true` | logs e health checks |

O parâmetro `DEPLOY` é `false` por defeito. O deployment a partir do Jenkins
requer um agente com Docker; o Jenkins local em contentor não tem o socket do
Docker montado. Por isso, a validação local do deployment foi feita a partir do
host com os scripts de `deploy/`.

## Fase 2 — Deployment local

Foram criados três ambientes lógicos, cada um com o seu contentor, volume e
configuração:

| Ambiente | URL local | Perfil Spring | Dados | Uso |
|---|---|---|---|---|
| dev | `http://localhost:8091` | `bootstrap,dev` | volume `lms-dev-data` | desenvolvimento e demonstração |
| staging | `http://localhost:8092` | `bootstrap,staging` | volume `lms-staging-data` | pré-produção e testes |
| prod | `http://localhost:8093` | `prod` | volume `lms-prod-data` | produção local, sem dados de bootstrap |

Os portos 8091/8092/8093 foram escolhidos para não colidir com o Adminer
(8081) e com o Jenkins (8080).

### Comandos

```powershell
powershell -ExecutionPolicy Bypass -File deploy\deploy.ps1 -Env dev -Tag local
powershell -ExecutionPolicy Bypass -File deploy\deploy.ps1 -Env staging -Tag local
powershell -ExecutionPolicy Bypass -File deploy\deploy.ps1 -Env prod -Tag local
```

Em Linux/VM:

```bash
bash deploy/deploy.sh dev local
bash deploy/deploy.sh staging local
bash deploy/deploy.sh prod local
```

Cada deployment:

1. constrói a imagem `odsoft-lms:<tag>`;
2. sobe o contentor do ambiente;
3. espera pelo `/actuator/health`;
4. guarda a tag anterior em `.deploy/<ambiente>.previous`;
5. se o health check falhar, tenta reverter para a tag anterior.

Validação rápida:

```powershell
powershell -ExecutionPolicy Bypass -File deploy\smoke.ps1 -Env dev
powershell -ExecutionPolicy Bypass -File deploy\smoke.ps1 -Env staging
powershell -ExecutionPolicy Bypass -File deploy\smoke.ps1 -Env prod
```

Evidências locais:

```
evidence/deploy/summary.txt
evidence/deploy/health-dev.json
evidence/deploy/health-staging.json
evidence/deploy/health-prod.json
evidence/deploy/login-staging.json
evidence/deploy/docker-compose-ps-final.txt
```

Resultado observado:

- `dev`, `staging` e `prod` responderam `200` em `/actuator/health`;
- o login de bibliotecário em staging respondeu `200`.

O `prod` não usa o perfil `bootstrap`, por isso arranca sem dados de
demonstração. `dev` e `staging` usam `bootstrap` para permitir testar a
aplicação com os dados iniciais.

### Configuração

- `application-dev.properties`, `application-staging.properties` e
  `application-prod.properties`;
- chaves JWT externalizáveis por `JWT_PRIVATE_KEY`/`JWT_PUBLIC_KEY`;
- chave Api Ninjas externalizada por `NINJAS_KEY`;
- Actuator exposto apenas em `health` e `info`;
- `/actuator/health` é público para o health check de deployment;
- `spring.jpa.open-in-view=false`; as authorities do utilizador passaram a
  `EAGER` para a autenticação funcionar sem sessão aberta.

## Fase 3 — Testes, mutação e quality gates

### Estratégia

A Fase 3 cobre os cinco níveis da rubrica C2:

- **C2.1 — caixa opaca em classes**: testes dos modelos e contratos públicos;
- **C2.2 — caixa transparente no domínio**: casos de limites, ramos e erros;
- **C2.3 — mutação**: PIT sobre as classes de domínio;
- **C2.4 — integração de componentes**: testes de repositórios e serviços com
  Spring e H2;
- **C2.5 — sistema**: `SystemTest` com servidor HTTP real, login, pesquisa
  autenticada e acesso sem token.

A suite passou de 102 para **116 testes**. Os testes novos incluem 5 de sistema
e 9 de domínio. O `SystemTest` usa uma base H2 própria
(`jdbc:h2:mem:systemtest`) para não partilhar dados com os testes de empréstimos
e ser independente da ordem de execução.

### Resultados

| Indicador | Baseline | Após Fase 3 |
|---|---:|---:|
| Testes | 102 | 116 |
| `mvn clean test` | 43,4 s | 1 min 18 s |
| `mvn clean verify` | — | 1 min 19 s |
| Cobertura de linhas | 19,5% | 38,6% |
| Cobertura de ramos | 4,5% | 10,0% |
| Mutantes PIT | — | 301 |
| Mutation score | — | 50% |
| Test strength PIT | — | 79% |
| PIT line coverage | — | 70% (classes mutadas) |

O aumento do tempo de teste deve-se sobretudo ao contexto Spring dos testes de
sistema e ao arranque da aplicação com o perfil `bootstrap`.

### Gates

- **JaCoCo**: linhas ≥35%, ramos ≥9%;
- **PIT**: mutation score ≥45%, coverage ≥65%;
- **Checkstyle/SpotBugs**: continuam em modo de relatório. O baseline tinha 109
  e 226 avisos; não foram usados como gate para não bloquear a entrega por
  dívida pré-existente. A dívida fica identificada para a Fase 4.

### Comandos

```bash
mvn clean verify
mvn -Dtest=SystemTest test
mvn org.pitest:pitest-maven:mutationCoverage
```

### Jenkins

O `Jenkinsfile` passou a ter os stages:

- `Tests` — inclui unitários, integração e sistema;
- `Coverage Gate`;
- `Mutation Testing`.

Os relatórios PIT e JaCoCo são arquivados e publicados como HTML.

### Evidências

```
evidence/phase3/summary.txt
evidence/phase3/mvn-verify.txt
evidence/phase3/mvn-test-final.txt
evidence/phase3/jacoco-final.csv
evidence/phase3/pit-final.txt
evidence/phase3/pit/mutations.xml
evidence/phase3/pit/index.html
evidence/phase3/mvn-test-reverse.txt
evidence/phase3/coverage-gate.txt
evidence/jenkins-vm/build-6-console.txt
evidence/jenkins-vm/build-6-summary.txt
evidence/jenkins-vm/build-8-console.txt
evidence/jenkins-vm/build-8-summary.txt
```

### Limitações

- PIT incide apenas nas classes de domínio; serviços e controllers não são
  mutados nesta fase.
- Os mutantes sem cobertura e os sobreviventes devem ser analisados na Fase 4
  para decidir quais são equivalentes e quais exigem mais testes.
- Checkstyle/SpotBugs ainda não são gates bloqueantes.
- O build #6 foi manual; o build #8 foi automático via webhook. C1.2 está
  validado.

## Estrutura

```
projeto_odsoft_1240447/
├── Jenkinsfile
├── Dockerfile
├── docker-compose.yml
├── config/checkstyle/checkstyle.xml
├── deploy/
│   ├── deploy.sh
│   ├── deploy.ps1
│   ├── smoke.sh
│   ├── smoke.ps1
│   └── vm/
│       ├── setup.sh
│       ├── deploy.sh
│       ├── smoke.sh
│       ├── odsoft-dev.service
│       ├── odsoft-staging.service
│       └── odsoft-prod.service
├── jenkins/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── plugins.txt
│   ├── odsoft-p1-job.xml
│   └── init.groovy.d/01-security.groovy
├── evidence/
│   ├── baseline/
│   ├── deploy/
│   ├── jenkins/
│   ├── phase3/
│   └── vm/
├── src/
│   └── test/java/.../system/SystemTest.java
└── README.md
```

## Fase 2 na VM — JAR + systemd

Como a VM é um contentor LXC com 1,9 GB de RAM, o deployment na VM usa JARs
com `systemd`, não Docker.

O deployment foi validado na VM `vs264`:

| Ambiente | URL pública | Resultado |
|---|---|---|
| dev | `http://vsgate-http.dei.isep.ipp.pt:10264` | `/actuator/health` = 200 |
| staging | `http://vsgate-s2.dei.isep.ipp.pt:10264` | `/actuator/health` = 200; login = 200 |
| prod | `https://vs-gate.dei.isep.ipp.pt:30264` | `/actuator/health` = 200 |
| Jenkins | `https://vs-gate.dei.isep.ipp.pt:10264` | login = 200 |

Evidências:

```
evidence/vm/summary.txt
evidence/vm/health-dev.json
evidence/vm/health-staging.json
evidence/vm/health-prod.json
evidence/vm/login-staging.json
```

### Instalar os serviços

No VS, a partir de `/opt/odsoft/repo`:

```bash
git pull
sudo bash deploy/vm/setup.sh
```

O setup cria:

- utilizador de sistema `odsoft`;
- `/opt/odsoft/{releases,data,logs}`;
- serviços `odsoft-dev`, `odsoft-staging` e `odsoft-prod`;
- comando `/usr/local/bin/odsoft-deploy`;
- permissão `sudo` para o utilizador `jenkins` executar apenas esse comando.

### Deploy manual

```bash
sudo /usr/local/bin/odsoft-deploy dev 1 \
  /var/lib/jenkins/workspace/odsoft-p1/target/projeto-odsoft-1240447-0.0.1-SNAPSHOT.jar

sudo /usr/local/bin/odsoft-deploy staging 1 \
  /var/lib/jenkins/workspace/odsoft-p1/target/projeto-odsoft-1240447-0.0.1-SNAPSHOT.jar

sudo /usr/local/bin/odsoft-deploy prod 1 \
  /var/lib/jenkins/workspace/odsoft-p1/target/projeto-odsoft-1240447-0.0.1-SNAPSHOT.jar
```

### Verificar

```bash
systemctl status odsoft-dev odsoft-staging odsoft-prod --no-pager
bash deploy/vm/smoke.sh dev
bash deploy/vm/smoke.sh staging
bash deploy/vm/smoke.sh prod
```

Portas internas:

| Ambiente | Porta | URL pública |
|---|---:|---|
| dev | 2224 | `http://vsgate-http.dei.isep.ipp.pt:10264` |
| staging | 2225 | `http://vsgate-s2.dei.isep.ipp.pt:10264` |
| prod | 2228 | `https://vs-gate.dei.isep.ipp.pt:30264` |

No Jenkins, o job pode fazer o deployment com:

- `DEPLOY = true`;
- `DEPLOY_MODE = vm`.

O stage usa `sudo /usr/local/bin/odsoft-deploy`, que copia o JAR para
`/opt/odsoft/releases/<build>`, atualiza o link do ambiente, reinicia o serviço
e valida `/actuator/health`.

## Segundo contexto — VM DEI

O Jenkins está instalado no `vs264` e o build do pipeline já passou na VM.
Para repetir a instalação base, seguindo o material da unidade curricular, os
comandos são:

```bash
sudo apt update
sudo apt install -y openjdk-21-jdk maven git curl

curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key \
  | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install -y jenkins

# Ajustar a porta, se for necessario (o material usa 2226)
sudo sed -i 's/JENKINS_PORT=8080/JENKINS_PORT=2226/' /lib/systemd/system/jenkins.service
sudo systemctl daemon-reload
sudo systemctl restart jenkins
```

Depois:

1. instalar os mesmos plugins de `jenkins/plugins.txt`;
2. configurar JDK 17 e Maven;
3. criar o job `odsoft-p1` por SCM, com a URL do repositório ODSOFT;
4. executar o pipeline e guardar os logs em `evidence/jenkins-vm/`;
5. comparar os dois contextos (versão, plugins, permissões, conectividade,
   tempo de build e limitações).

A VM está operacional; o deployment por JAR + systemd está preparado na secção
anterior. O Docker não é usado na VM por causa das limitações do LXC e da
memória disponível.

## Relação com a rubrica ODSOFT

| Critério | Estado na Fase 1 |
|---|---|
| C1.1 Jenkins em dois contextos | Local implementado; VM DEI com Jenkins e build do pipeline validado |
| C1.2 Integração SCM e execução automática | `Jenkinsfile` versionado; job `odsoft-p1` por SCM executado na VM |
| C1.3 Build, análise estática, packaging e testes | Pipeline com 116 testes, testes de sistema, mutação e gates |
| C1.4 Deployment em destinos distintos | Validado em Docker local e na VM com JAR + systemd |
| C1.5 Ambientes dev/staging/prod | Validado nos três ambientes, com health checks públicos |
| C2.1–C2.5 Testes | 116 testes; C2.1/C2.2, C2.4 e C2.5 cobertos; PIT em C2.3 |
| C3.1 System-as-is | Baseline, logs e métricas iniciais |
| C3.2 System-to-be | Pipeline, testes e decisões documentados |
| C3.3 Análise crítica e melhoria | Comparação antes/depois feita; relatório final na Fase 4 |
| C4.1–C4.2 Consistência e rastreabilidade | A fechar na Fase 4 |

## Próximas fases

1. **Fase 2 (concluída)** — deployment para dev/staging/prod, artefactos
   versionados, promoção, smoke tests e rollback, local e na VM DEI.
2. **Fase 3 (concluída)** — testes de sistema, mutação PIT, cobertura, gates e
   comparação com o baseline.
3. **Fase 4** — relatório final, diagramas, rastreabilidade, evidências e
   demonstração.

## Nota sobre o base

O `pom.xml` é o mesmo do LMS usado em ARQSOFT. O código de ARQSOFT não foi
copiado para este repositório; foi usado o baseline `main`, sem as extensões de
políticas de empréstimo, para manter o âmbito ODSOFT isolado.
