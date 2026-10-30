# projeto_odsoft_1240447

Projeto 1 da unidade curricular de Organização do Desenvolvimento de Software
(ODSOFT), 2026-2027.

O ponto de partida é o serviço REST de gestão de biblioteca desenvolvido em
PSOFT (`psoft-project-2024-g1`). Este repositório é independente do projeto de
ARQSOFT: o código base é o mesmo, mas o âmbito é diferente. O ODSOFT não pede
novas funcionalidades de biblioteca; pede a evolução do processo de build,
testes, integração, entrega e deployment.

## Estado atual — Fase 1

Implementado:

- repositório independente com o baseline do LMS;
- baseline de testes e de build medido e guardado;
- Maven com JaCoCo, Checkstyle, SpotBugs e Maven Enforcer;
- `Jenkinsfile` declarativo com checkout, build, análise estática, testes,
  cobertura e packaging;
- Jenkins local em Docker (`jenkins/`);
- relatórios de testes, cobertura e análise estática arquivados pelo pipeline;
- job `odsoft-p1` criado por SCM e build **#3 com sucesso** (102 testes,
  173,5 s), com evidências em `evidence/jenkins/`.

Ainda não implementado:

- segundo contexto Jenkins na VM DEI (falta acesso/credenciais);
- deployment para dev/staging/prod (Fase 2);
- testes de mutação, testes de sistema e quality gates finais (Fase 3);
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

Estes valores são o ponto de partida; não são a qualidade final. A Fase 3 vai
melhorar a suite e voltar a medir com as mesmas condições.

Os logs estão em:

```
evidence/baseline/mvn-test.txt
evidence/baseline/mvn-package.txt
evidence/baseline/summary.txt
```

## Como validar localmente

```bash
mvn -B clean test
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
montado em `/workspace`. O build #3 demorou 173,5 s e produziu os relatórios de
testes, cobertura e Checkstyle. As evidências estão em:

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
| Unit Tests | `mvn test` | Surefire XML |
| Coverage | `mvn jacoco:report` | JaCoCo HTML/XML/CSV |
| Package | `mvn package` | JAR em `target/` |

O pipeline corre em qualquer agente. Para já não faz deployment; essa parte
pertence à Fase 2.

## Estrutura

```
projeto_odsoft_1240447/
├── Jenkinsfile
├── config/checkstyle/checkstyle.xml
├── jenkins/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── plugins.txt
│   ├── odsoft-p1-job.xml
│   └── init.groovy.d/01-security.groovy
├── evidence/
│   ├── baseline/
│   └── jenkins/
├── src/
└── README.md
```

## Segundo contexto — VM DEI (pendente)

Para fechar o C1.1 falta executar o pipeline na VM DEI. A instalação base,
seguindo o material da unidade curricular, é:

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

Sem acesso/credenciais à VM, esta parte fica explicitamente pendente; não foi
simulada como se estivesse concluída.

## Relação com a rubrica ODSOFT

| Critério | Estado na Fase 1 |
|---|---|
| C1.1 Jenkins em dois contextos | Local implementado e validado; VM DEI pendente |
| C1.2 Integração SCM e execução automática | `Jenkinsfile` versionado; job `odsoft-p1` por SCM executado |
| C1.3 Build, análise estática, packaging e testes | Implementado no pipeline; build #3 SUCCESS |
| C1.4 Deployment em destinos distintos | Fase 2 |
| C1.5 Ambientes dev/staging/prod | Fase 2 |
| C2.1–C2.5 Testes | Suite base existe; melhoria na Fase 3 |
| C3.1 System-as-is | Baseline e logs iniciais |
| C3.2 System-to-be | Pipeline e decisões iniciais |
| C3.3 Análise crítica e melhoria | Fase 3/4, com comparação antes/depois |
| C4.1–C4.2 Consistência e rastreabilidade | A fechar na Fase 4 |

## Próximas fases

1. **Fase 2** — deployment para dev/staging/prod, artefactos versionados,
   promoção, smoke tests e rollback.
2. **Fase 3** — testes de mutação, testes de sistema, quality gates, melhoria
   da cobertura e comparação com o baseline.
3. **Fase 4** — relatório final, diagramas, rastreabilidade, evidências e
   demonstração.

## Nota sobre o base

O `pom.xml` é o mesmo do LMS usado em ARQSOFT. O código de ARQSOFT não foi
copiado para este repositório; foi usado o baseline `main`, sem as extensões de
políticas de empréstimo, para manter o âmbito ODSOFT isolado.
