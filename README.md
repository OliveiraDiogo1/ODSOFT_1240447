# P1 ODSOFT (2026/2027)

## Contexto e âmbito

Este repositório possui o Projeto 1 de Organização do Desenvolvimento de
Software. O ponto de partida é o mesmo serviço REST de gestão de biblioteca
usado em ARQSOFT (psoft-project-2024-g1). O objetivo é o processo de build,
testes, integração, entrega e deplou, sem introduzir funcionalidades de
biblioteca.

O repositório é independente do projeto de ARQSOFT. Foi usado como base a branch
main, sem as extensões de políticas de empréstimo e não foi copiado código de
ARQSOFT para este repositório.

Repositório remoto:

<https://github.com/OliveiraDiogo1/ODSOFT_1240447>

O estado final está na branch main. O build automático (#8) foi executado
no commit #41a3379; os commits posteriores possuem apenas evidências e
documentação.

## Baseline

O baseline foi medido antes de acrescentar os plugins de qualidade e serve de
comparação para a análise de resultados.

| Indicador | Valor inicial |
| --- | ---: |
| Testes executados | 102 |
| Falhas | 0 |
| mvn clean test | 43,4 s |
| mvn -DskipTests package | 14,5 s |
| Cobertura de linhas | 19,5% (558 de 2 868) |
| Cobertura de ramos | 4,5% (117 de 2 579) |
| Avisos Checkstyle | 109 |
| Avisos SpotBugs | 226 |

Os registos estão em:

```
evidence/baseline/mvn-test.txt
evidence/baseline/mvn-package.txt
evidence/baseline/summary.txt
evidence/baseline/quality-metrics.txt
evidence/baseline/jacoco.csv
```

O projeto base tinha testes unitários e de integração. Não tinha mutação,
testes de sistema, webhook, quality gates de cobertura e mutação, nem deployment
repetível entre ambientes.

## Processo CI/CD

### Jenkins em dois contextos

Foram usados dois contextos de execução:

1. Jenkins local em Docker, em `jenkins/`;
2. Jenkins na VM DEI (vs264).

O job odsoft-p1 é um Pipeline script from SCM, com o Jenkinsfile
no repositório e a branch main. Na Virtual Machine, o checkout usa HTTPS e a credencial
github-pat (access key criada nas definições pessoais do github); o webhook GitHub entrega os eventos ao Jenkins.

O Jenkins local executou o build #4 com 102 testes em 90,4 s. Na Virtual Machine, o build #6
foi executado manualmente, no commit `#75acc4e`, com 116 testes. O build #8 foi
iniciado , automáticamente, por um push no GitHub, no commit `#41a3379` e terminou, também, com sucesso. O push
e ping do webhook devolveram **200**.

Com *DEPLOY=false*, a build #8 correu testes, cobertura, mutação e packaging,
mas não executou deployment. O deployment foi validado separadamente na Fase 2.

### Pipeline

| Stage | Operação | Resultado ou relatório |
| --- | --- | --- |
| Checkout | obtém o commit do GitHub | GIT_COMMIT e GIT_BRANCH |
| Build | *mvn clean compile* | log Maven |
| Static Analysis | Checkstyle e SpotBugs | XML e HTML |
| Tests | *mvn test*, incluindo testes de sistema | Surefire XML |
| Coverage | *mvn jacoco:report* | JaCoCo HTML/XML/CSV |
| Coverage Gate | *mvn jacoco:check* | falha se os limites não forem cumpridos |
| Mutation Testing | *mvn pitest:mutationCoverage* | relatório PIT |
| Package | *mvn -DskipTests package* | JAR em target/ |
| Deploy/Smoke Dev, Staging, Prod | apenas com *DEPLOY=true* | logs e health checks |

A pipeline publica os relatórios JUnit, Checkstyle, JaCoCo e PIT e arquiva o JAR.
O parâmetro *DEPLOY* é false por omissão. O *DEPLOY_MODE* permite escolher
vm (JAR + systemd) ou docker.

O diagrama do pipeline
está em [Docs/pipeline.puml](Docs/pipeline.puml).

### Evidências de execução

```
evidence/jenkins/build-summary.txt
evidence/jenkins/build-console.txt
evidence/jenkins/build-api.json
evidence/jenkins/jenkinsfile-validation.txt
evidence/jenkins/version.txt
evidence/jenkins/plugins.txt
evidence/jenkins-vm/build-6-console.txt
evidence/jenkins-vm/build-6-summary.txt
evidence/jenkins-vm/build-8-console.txt
evidence/jenkins-vm/build-8-summary.txt
```

Os logs do build #8 mostram o commit **#41a3379**, 116 testes, a passagem do
*Coverage Gate*, o PIT e o package. O build #8 não é prova de que os ambientes
estão atualmente disponíveis; os health checks foram registados nas execuções
indicadas em evidence/.

## Deployment e ambientes

### Docker local

Foram criados três ambientes locais com containeres, volumes e perfis distintos:

| Ambiente | URL local | Perfil Spring | Dados |
| --- | --- | --- | --- |
| dev | `http://localhost:8091` | *bootstrap,dev* | volume lms-dev-data |
| staging | `http://localhost:8092` | *bootstrap,staging* | volume lms-staging-data |
| prod | `http://localhost:8093` | *prod* | volume lms-prod-data |

Os ports 8091, 8092 e 8093 não colidem com o Adminer (8081) nem com o Jenkins
local (8080). O *prod* não usa o perfil *bootstrap*. *Dev* e *staging* usam-no
para ter dados de demo.

Os scripts de deployment constroem a imagem `odsoft-lms:<tag>`, sobem o
container do ambiente, esperam pelo `/actuator/health`, guardam a tag anterior em
`.deploy/<ambiente>.previous` e tentam reverter se o health check falhar.

```
powershell -ExecutionPolicy Bypass -File deploy\deploy.ps1 -Env dev -Tag local
powershell -ExecutionPolicy Bypass -File deploy\deploy.ps1 -Env staging -Tag local
powershell -ExecutionPolicy Bypass -File deploy\deploy.ps1 -Env prod -Tag local
```

Em Linux (Virtual Machine):

```
bash deploy/deploy.sh dev local
bash deploy/deploy.sh staging local
bash deploy/deploy.sh prod local
```

Os smoke tests locais estão em deploy/smoke.ps1 e deploy/smoke.sh.

As
evidências registadas em `evidence/deploy/` mostram health **200** nos três
ambientes e login **200** em staging. Estes valores são históricos e não foram
verificados novamente nesta revisão.

### Virtual Machine

A Virtual Machine é um container LXC com 1,9 GB de RAM. Por isso, o deployment na VM usa JAR
e systemd e não Docker.

| Ambiente | Porta interna | URL pública |
| --- | ---: | --- |
| dev | 2224 | `http://vsgate-http.dei.isep.ipp.pt:10264` |
| staging | 2225 | `http://vsgate-s2.dei.isep.ipp.pt:10264` |
| prod | 2228 | `https://vs-gate.dei.isep.ipp.pt:30264` |
| Jenkins | 2226 | `https://vs-gate.dei.isep.ipp.pt:10264` |

O setup em /opt/odsoft/repo é feito com:

```
git pull
sudo bash deploy/vm/setup.sh
```

O setup cria o utilizador odsoft, os diretórios
`/opt/odsoft/{releases,data,logs}`, os serviços odsoft-dev/staging e prod, o comando `/usr/local/bin/odsoft-deploy` e a permissão de sudo para o utilizador *jenkins* executar apenas esse comando.

O deployment de um JAR é feito com:

```
JAR=/var/lib/jenkins/workspace/odsoft-p1/target/projeto-odsoft-1240447-0.0.1-SNAPSHOT.jar
sudo /usr/local/bin/odsoft-deploy dev <tag> "$JAR"
sudo /usr/local/bin/odsoft-deploy staging <tag> "$JAR"
sudo /usr/local/bin/odsoft-deploy prod <tag> "$JAR"
```

O comando copia o JAR para `/opt/odsoft/releases/<tag>`, atualiza o link
`current-<ambiente>`, reinicia o serviço, valida `/actuator/health` e volta ao
link anterior se a validação falhar. O mesmo jar é passado entre
ambiente ,não é reconstruído por ambiente.

Verificação:

```
systemctl status odsoft-dev odsoft-staging odsoft-prod --no-pager
bash deploy/vm/smoke.sh dev
bash deploy/vm/smoke.sh staging
bash deploy/vm/smoke.sh prod
```

Os resultados de health e login em `evidence/vm/` foram registados nas execuções
de deployment; não comprovam disponibilidade atual. O diagrama dos ambientes
está em [Docs/ambientes.puml](Docs/ambientes.puml).

### Jenkins na VM

A instalação base usada na VM foi:

```
sudo apt update
sudo apt install -y openjdk-21-jdk maven git curl
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key \
  | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install -y jenkins
sudo sed -i 's/JENKINS_PORT=8080/JENKINS_PORT=2226/' /lib/systemd/system/jenkins.service
sudo systemctl daemon-reload
sudo systemctl restart jenkins
```

Foram instalados os plugins de `jenkins/plugins.txt`, configurado JDK 17 e
Maven, criado o job `odsoft-p1` por SCM e guardados os logs em
`evidence/jenkins-vm/`. A última execução local registada é o build #4. O
container local não foi consultado nesta revisão.

## Testes

A suite foi organizada segundo os cinco níveis da rubrica C2:

| Nível | Implementação |
| --- | --- |
| C2.1: caixa opaca em classes | testes dos modelos e contratos públicos |
| C2.2: caixa transparente no domínio | limites, ramos, erros e getters |
| C2.3: mutação | PIT nas classes de domínio |
| C2.4: integração de componentes | repositórios e serviços com Spring/H2 |
| C2.5: sistema | SystemTest com servidor HTTP real, login, pesquisa e acesso sem token |

A suite passou de 102 para 116 testes: 5 de sistema e 9 de domínio. O
SystemTest usa uma base H2 própria (`jdbc:h2:mem:systemtest`) para não
partilhar dados com os testes de empréstimos e ser independente da ordem de
execução. A execução com ordem inversa também foi validada com 116 testes.

Comandos:

```
mvn clean verify
mvn -Dtest=SystemTest test
mvn org.pitest:pitest-maven:mutationCoverage
```

O diagrama da estratégia de testes está em
[Docs/testes.puml](Docs/testes.puml).

## Resultados e análise

| Indicador | Baseline | Final |
| --- | ---: | ---: |
| Testes | 102 | 116 |
| *mvn clean test* | 43,4 s | 1 min 18 s |
| *mvn clean verify* | - | 1 min 19 s |
| Cobertura de linhas | 19,5% | 38,6% |
| Cobertura de ramos | 4,5% | 10,0% |
| Mutantes PIT | - | 301 |
| Mutantes mortos | - | 152 |
| Mutation score | - | 50% |
| Test strength | - | 79% |
| Cobertura PIT das classes mutadas | - | 70% (348 de 500) |
| Testes executados pelo PIT | - | 437 |
| Checkstyle | 109 avisos | 110 avisos |
| Build automático | não | #8, commit `#41a3379` |

A cobertura de 38,6% vem do JaCoCo e abrange o projeto. A de 70% refere-se apenas
às classes analisadas pelo PIT. Os gates configurados são 35% de linhas e 9% de
ramos no JaCoCo, 45% de mutação e 65% de cobertura no PIT.

Os valores de testes, cobertura e mutação da tabela são de execuções locais. Os
builds #6 e #8 correram na VM e registaram 116 testes; os resultados de
deployment na VM estão em evidence/vm/.

O que melhorou:

- A suite passou a incluir testes de sistema e mutação;
- A cobertura de linhas e de ramos aumentou;
- O pipeline passou a falhar quando a cobertura ou a mutação ficam abaixo dos gates;
- O webhook foi validado com o build automático #8;
- O deployment passou a ter um procedimento repetível e evidências por ambiente.

O que continua limitado:

- A cobertura global é baixa porque a maior parte do código base não foi
  alterada neste projeto;
- O PIT tem 50% e incide apenas nas classes de domínio; os mutantes sem cobertura
  e os sobreviventes não foram analisados nem classificados como equivalentes;
- Checkstyle e SpotBugs continuam em modo de relatório; os 109 e 226 avisos
  iniciais não são gates;
- A build #8 não executou deployment, porque `DEPLOY=false`. O deployment foi
  validado na Fase 2;
- A VM tem 1,9 GB, o que limita a execução concorrente de builds e testes;
- Não foram usados SonarQube nem Kubernetes; a solução ficou limitada às
  ferramentas necessárias ao âmbito.

O tempo de `mvn clean test` passou de 43,4 s para 1 min 18 s. A diferença
coincide com a introdução dos testes de sistema com contexto Spring e com a
execução do PIT, que corre a suite várias vezes. Não foi feita uma decomposição
formal do tempo por stage.

As evidências de testes e qualidade estão em:

```
evidence/phase3/mvn-test-final.txt
evidence/phase3/summary.txt
evidence/phase3/mvn-test-reverse.txt
evidence/phase3/mvn-verify.txt
evidence/phase3/jacoco-final.csv
evidence/phase3/pit-final.txt
evidence/phase3/pit/mutations.xml
evidence/phase3/pit/index.html
evidence/phase3/coverage-gate.txt
```

## Rastreabilidade

| Critério | Objetivo ou decisão | Alteração ou execução | Evidência |
| --- | --- | --- | --- |
| C1.1 | Jenkins em dois contextos | Docker local e Virtual Machine | builds #4, #6 e #8 |
| C1.2 | SCM e execução automática | Jenkinsfile, webhook e github-pat (credencial) | build #8 |
| C1.3 | Build, análise, packaging e testes | stages e 116 testes | evidence/phase3/ |
| C1.4 | Deployment em destinos distintos | Docker local e JAR/systemd na VM | evidence/deploy/ e evidence/vm/ |
| C1.5 | dev, staging e prod | perfis, portas e dados separados | health checks e login registados |
| C2.1/C2.2 | Classes e domínio | testes unitários e de domínio | suite de 116 testes |
| C2.3 | Mutação | PIT | 301 mutantes, 152 mortos, 50% |
| C2.4 | Integração de componentes | testes Spring/H2 | testes de repositório e serviço |
| C2.5 | Sistema | SystemTest | 5 testes de sistema |
| C3.1 | System-as-is | baseline | evidence/baseline/ |
| C3.2 | System-to-be | pipeline e decisões | Jenkinsfile e README |
| C3.3 | Análise crítica | comparação baseline/final | tabela da secção 6 |
| C4.1 | Consistência | requisitos, pipeline e testes | esta matriz |
| C4.2 | Rastreabilidade | commits, builds e evidências | `#41a3379`, build #8 |

## Limitações e trabalho futuro

- Ampliar o PIT a serviços e controllers e analisar os mutantes sobreviventes.
- Reduzir os avisos de Checkstyle e SpotBugs antes de os transformar em gates.
- Executar deployment a partir do pipeline com `DEPLOY=true`; o build #8 não o
  fez.
- Repetir builds para avaliar estabilidade e variabilidade dos tempos.
- Rever a necessidade de SonarQube ou outra ferramenta de análise contínua.
- Confirmar que os ambientes continuam disponíveis antes de uma demonstração;
  os health checks existentes são históricos.

## Reprodução e demonstração

Build local:

```
mvn -B clean verify
mvn -B -Dtest=SystemTest test
mvn -B org.pitest:pitest-maven:mutationCoverage
```

Jenkins local:

```
cd jenkins
docker compose build
docker compose up -d
```

O Jenkins local fica em <http://localhost:8080>. Depois do arranque, é necessário
instalar os plugins de jenkins/plugins.txt, configurar JDK 17 e Maven e criar o
job `odsoft-p1` como Pipeline script from SCM, apontado para a branch **main** e
com Jenkinsfile como script path. O ficheiro **jenkins/odsoft-p1-job.xml** documenta a configuração usada. A password inicial e as credenciais locais não
são documentadas.

Para o deployment na VM, os comandos de setup, deployment e verificação estão
na secção 4.2. Para uma demonstração, devem abrir-se os ambientes e confirmar o
health no momento; os valores registados nas evidências não substituem essa
verificação.

A build #8 foi registada em:

<https://vs-gate.dei.isep.ipp.pt:10264/job/odsoft-p1/8/>

## Estrutura do Projeto

```text
projeto_odsoft_1240447/
├── Jenkinsfile
├── Dockerfile
├── docker-compose.yml
├── config/checkstyle/checkstyle.xml
├── Docs/
│   ├── pipeline.puml
│   ├── ambientes.puml
│   └── testes.puml
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
│   ├── jenkins-vm/
│   ├── phase3/
│   └── vm/
├── src/
│   └── test/java/.../system/SystemTest.java
└── README.md
```
