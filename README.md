---
HW 27
---

Задание со *

Согласно опции масштабирования `mode: replicated` node-exporter запустился на всех машинах. Все новые реплики сервисов запустились на новом worker.

Для нескольких вариантов окружений можно использовать определение файла переменных:

```
prometheus:
  image: ${USER_NAME}/prometheus
  env_file:
     - .env
```
далее в нескольких файлах env указать необходимые переменные в зависимости от окружения в файле docker-compose.override.yml.

Или попровывать передать само название файла через переменную в зависимости от окружения.

Создание хостов для SWARM
```
docker-machine create --driver google \
   --google-project  docker-1948171 \
   --google-zone europe-west1-b \
   --google-machine-type g1-small \
   --google-machine-image $(gcloud compute images list --filter ubuntu-1604-lts --uri) \
   master-1
```
Инициализация docker SWARM

```
docker swarm init
```
Вывод команды и ввод нод в кластер:

```
docker swarm join --token SWMTKN-1-3eoop9he6otjcgjhmbxl99h4s75g8ps3vu1v75b181h0b2oued 10.0.0.3:2377
```

Генерация token для подключения master или worker:

```
docker swarm join-token manager/worker
```
Проверка состояние кластера:

```
docker node ls
```

Сервисы и их зависимости объединяются в STACK. STACK описывается в виде yml формата как в compose.

Управление Stack:

```
docker stack deploy/rm/services/ls STACK_NAME
```

Запуск STACK `docker stack deploy  --compose-file docker-compose.yml ENV` но SWARM не поддерживает описание переменных, но для этого можно использовать обходное решение:

```
docker stack deploy --compose-file=<(docker-compose -f docker-compose.yml config 2>/dev/null) DEV
```

Ограничения размещения определяются с помощьюл огических действий со значениями label-ов (медатанных) нод и docker-engine’ов Обращение к встроенным label’ам нод - node.*  Обращение к заданным в ручную label’ам нод - node.labels*  Обращениек label’ам engine - engine.labels.*

Обращение к встроенным label’ам нод - node.*   
Обращение к заданным вручную label’ам нод - node.labels*   
Обращение к label’ам engine - engine.labels.*
 
Примеры:
-
node.labels.reliability == high
-
node.role != manager
-
engine.labels.provider == google


Назначение лейблов:

```
docker node update --label-add reliability=high master-1
```
SWARM не умеет пока фильтровать вывод по label но можно выполнить:

```
docker node ls -q | xargs docker node inspect  -f '{{ .ID }} [{{ .Description.Hostname }}]: {{ .Spec.Labels }}'
```

Масштабирование сервисов:

1. replicated mode - запустить определенное число задач
(default)

2. global mode - запустить задачу на каждой ноде

```
deploy:
  mode: replicated
  replicas: 2
```
Управление кол-вом запускаемых сервисов в на лету:

```
docker service scale DEV_ui=3
docker service update --replicas 3 DEV_ui
```

Выключить все задачи сервиса:

```
docker service update --replicas 0 DEV_ui
```
Выяснить ID контейнера можно:

```
docker inspect $(docker stack ps swarm -q --filter "Name=swarm_ui.1") --format "{{.Status.ContainerStatus.ContainerID}}"
```

Параметры деплоя:

1. parallelism - cколько контейнеров (группу) обновить
одновременно?
2. delay - задержка между обновлениями групп контейнеров  
3. order - порядок обновлений (сначала убиваем старые и
запускаем новые или наоборот) (только в compose 3.4) 

Обработка ошибочных ситуаций:

4. failure_action - что делать, если при обновлении возникла ошибка
5.  monitor - сколько следить за обновлением, пока не признать его
удачным или ошибочным
6. max_failure_ratio - сколько раз обновление может пройти с
ошибкой перед тем, как перейти к failure_action

* rollback - откатить все задачи на предыдущую версию
* pause (default) -  приостановить обновление
* continue - продолжить обновле


```
service:
    image: svc
    deploy:
      update_config:
        parallelism: 2  
        delay: 5s
        failure_action: rollback
        monitor: 5s
        max_failure_ratio: 2
        order: start-firs
```

** Ограничение ресурсов resources limits

```
resources:
        limits:
          cpus: '0.50'
          memory: 150M
```

По умолчанию swarm контейнер запускает даже если ты его остановил, такую политику можно изменить с помощью Restart policy

```
restart_policy:
  condition: on-failure
  max_attempts: 10
  delay: 1s
```

Использование нескольких докер файлов

```
docker stack deploy --compose-file=<(docker-compose -f docker-compose.monitoring.yml -f docker-compose.yml config 2>/dev/null)  DEV
```

---
HW 25
---
ELK - elasticksearch, greylog, kibana
EFK - elasticksearch, Fluentd, kibana

* Сбор не структурированых логов

Использование регулярных выражений для логов сервиса ui - очень не удобно и легко ошибиться

```
<filter service.ui>
  @type parser
  format /\[(?<time>[^\]]*)\]  (?<level>\S+) (?<user>\S+)[\W]*service=(?<service>\S+)[\W]*event=(?<event>\S+)[\W]*(?:path=(?<path>\S+)[\W]*)?request_id=(?<request_id>\S+)[\W]*(?:remote_addr=(?<remote_addr>\S+)[\W]*)?(?:method= (?<method>\S+)[\W]*)?(?:response_status=(?<response_status>\S+)[\W]*)?(?:message='(?<message>[^\']*)[\W]*)?/
  key_name log
</filter>
```

Более удобно это использование grok шалонов. grok’и - это именованные шаблоны регулярных выражений (очень похоже на функции). Можно использовать готовый regexp, просто сославшись на него как на функцию.

```
<filter service.ui>
  @type parser
  format grok
  grok_pattern service=%{WORD:service} \| event=%{WORD:event} \| request_id=%{GREEDYDATA:request_id} \| message='%{GREEDYDATA:message}'
  key_name message
  reserve_data true
</filter>
```

* Визуализация логов

Kibana -  визуализация от компании Elastic. Интерфейс доступен по порту 5601. Для сбора логов от fluentd нужно задать патерн fluentd-*

* Сбор структурированных логов

Фильтр для fluentd

```
<filter service.post>
  @type parser
  format json
  key_name log
</filter>
```

* Инфо

Конфиг /etc/docker/daemon.json или опция --log-driver json-file. Посмотреть лог при этом можно tail -f $(docker inspect -f {{.LogPath}} dockerpuma_ui_1) или в папке с контейнером.

Journald-драйвер - пишет в системный лог.
GCP-драйвер - пишет логи в Google Stackdrive, но при этом не работает docker log. /etc/docker/daemon.json

Другие драйверы Syslog, Gelf, Splunk, Fluentd,
* Distributed tracing
* Zipkin


---
HW 23
---
* Мониторинг Docker контейнеров
В папке docker файлы:

1. docker-compose.yml - сервисы приложения
2. docker-compose-monitoing.yml - сервисы мониторинга
Запуск сервисов мониторинга
`docker-compose -f docker-compose-monitoring.yml up -d`

В мониторинг добавлен сервис cAdvisor для наблюдения за состоянием докер контейнеров (CPU, RAM и тд). Имеется свой Web-UI.

* Визуализация метрик

В docker-compose-monitoing.yml добавлен сервис grafana/grafana:5.0.0
В папку grafana выгружены примеры бизнес метрик и приложения.

Пример:

`rate(ui_request_latency_seconds_count[60m])` - среднее количество и динамика (скорость увелечения) http запросв за 60 минут.

`histogram_quantile(0.95, sum(rate(ui_request_latency_seconds_bucket[5m])) by (le))` -  95-йперцентиль для выборки временио бработки запросов, чтобы посмотреть какое значение является максимальной границей дляб ольшинства (95%) запросов.

* Настройка и проверка алертинга

В папке alertmanager определим конфиг и Dockerfile для alertmanager:v0.14.0. Алерты будут приходить в slack.

!!!
 Чистка репозитория от нежелательных файлов, например случайно заккомиченых файлов паролей:
 git filter-branch --tree-filter 'rm -f имя_файла' master
 git push --force

Еще один инструмент для чистки репозитория BFG https://rtyley.github.io/bfg-repo-cleaner/

При удалении столкнулся с проблемой https://github.com/rtyley/bfg-repo-cleaner/issues/36.
---
HW 21
---
* Prometheus: запуск, конфигурация

Создание правил фаервола в GCP

gcloud compute firewall-rules create prometheus-default --allow tcp:9090
gcloud compute firewall-rules create puma-default --allow tcp:9292

Создание докер хоста:
export GOOGLE_PROJECT=_ваш-проект_
https://gist.github.com/isaidashev/a1216ff1c8c0503c3bde6275b71d9576

Сборка образов: `for i in ui post-py comment; do cd src/$i; bash docker_build.sh; cd -; done`

* Мониторинг состояния микросервисов

Логи с host сибираються с помощью node-exporter:v0.15.2. Добавляем его в docker-compose.yml

В конфиге prometheus.yml добавляем еще один Job для сбора логов:
```
- job_name: 'node'
  static_configs:
    - targets:
      - 'node-exporter:9100'

```
Веселая команда грузит проц:
```
yes > /dev/null
```
* Сбор метрик хоста с использованием экспортера  
* Задания со *


---
HW 20
---

1. Расширить действующий Pipline
* Инстраляцию gitlab осуществил с помощью terraform + ansible
* Создание нового проекта:
```
git checkout -b docker-7
git remote add gitlab2 http://<your-vm-ip>/homework/example2.git
git push gitlab2 docker-7 - pusy изменению в другой репозиторий
```
* Выполнение JOB по кнопке в интерфейсе:
```
when: manual
```

2. Определить окружения
* Оркужение:
```
environment:
  name: branch/$CI_COMMIT_REF_NAME
  url: http://$CI_ENVIRONMENT_SLUG.example.ru
```
* Выкатка только по TAG вида 2.4.10:

```
only:
  - /^\d+\.\d+.\d+
```
* Задать тег `git tag 2.4.10`

## Дополнительное задание
Работы пытался выполнить в ветке new-feature
1. Решил пойти путем разворачивания VM на GCE c через Terraform который запускается на Runner. Развернуть удалость.
2. Далее Ansible работает для настройки приложения на развернутом сервере. Столкнулся с проблемой подключения Ansible к развернтутой VM. Выдается ошибка связанная с ключами.  
```
""Failed to connect to the host via ssh: Warning: Permanently added '35.195.99.217' (ECDSA) to the list of known hosts.\r\nPermission denied (publickey)"
```
---
HW19
---

1. Подготовка инсталляции gitlabCI

* Виртуальная машина развернута с помощью Terraform
* Установка docker была осуществлена с помощью роли geerlingguy в ansible
* Окружение так же создано и запущен образ gitlab-ce с помощью ansible

2. Подготовка репозитория c кодом приложения

* Каждый проект в Gitlab CI принадлежит к группе проектов
* В проекте может быть определен CI/CD пайплайн
* Задачи (jobs) входящие в пайплайн должны исполняться на runners
* Добавил ветку в репозиторий `git remote add gitlab http://<your-vm-ip>/homework/example.git`

3. Описать для приложения этапы непрерывной интеграции

*  Создаем файл .gitlab-ci.yml в котором описан СI/CD Pipline:

```
stages:
  - build
  - test
  - review

build_job:
  stage: build
  script:
    - echo 'Building'

test_unit_job:
  stage: test
  script:
    - echo 'Testing 1'

test_integration_job:
  stage: test
  script:
    - echo 'Testing 2'

deploy_dev_job:
  stage: review
  script:
    - echo 'Deploy'
```

* Регистрация runner через меню настроек проекта Setting - Ci / CD - Runners setting
* Запуск докер контейнера для runner
`docker run -d --name gitlab-runner --restart always \ -v /srv/gitlab-runner/config:/etc/gitlab-runner \ -v /var/run/docker.sock:/var/run/docker.sock \ gitlab/gitlab-runner:latest`
`docker exec -it gitlab-runner gitlab-runner register` - ответить на задаваемые вопросы
* Провел тестирование приложения. Исправлял проблемы при установки GEM и проведения тестирования.

## Дополнитеное задание

В плане!!!

---
HW19
---

1. Подготовка инсталляции gitlabCI

* Виртуальная машина развернута с помощью Terraform
* Установка docker была осуществлена с помощью роли geerlingguy в ansible
* Окружение так же создано и запущен образ gitlab-ce с помощью ansible

2. Подготовка репозитория c кодом приложения

* Каждый проект в Gitlab CI принадлежит к группе проектов
* В проекте может быть определен CI/CD пайплайн
* Задачи (jobs) входящие в пайплайн должны исполняться на runners
* Добавил ветку в репозиторий `git remote add gitlab http://<your-vm-ip>/homework/example.git`

3. Описать для приложения этапы непрерывной интеграции

*  Создаем файл .gitlab-ci.yml в котором описан СI/CD Pipline:
```
stages:
  - build
  - test
  - deploy

build_job:
  stage: build
  script:
    - echo 'Building'

test_unit_job:
  stage: test
  script:
    - echo 'Testing 1'

test_integration_job:
  stage: test
  script:
    - echo 'Testing 2'

deploy_job:
  stage: deploy
  script:
    - echo 'Deploy'
```
* Регистрация runner через меню настроек проекта Setting - Ci / CD - Runners setting
* Запуск докер контейнера для runner
`docker run -d --name gitlab-runner --restart always \ -v /srv/gitlab-runner/config:/etc/gitlab-runner \ -v /var/run/docker.sock:/var/run/docker.sock \ gitlab/gitlab-runner:latest`
`docker exec -it gitlab-runner gitlab-runner register` - ответить на задаваемые вопросы
* Провел тестирование приложения. Исправлял проблемы при установки GEM и проведения тестирования.

## Дополнитеное задание

В плане!!!

---
HW17
---
1. Работа с сетью

### None, Host, bridge

Host - два сервиса на могут запускаться на одном порту.
Docker при инициализации контейнера может подключить к нему только 1 сеть

Запуск проекта в двух bridge сетях

`docker network create back_net --subnet=10.0.2.0/24`
`docker network create front_net --subnet=10.0.1.0/24`

```
docker run -d --network=back_net --network-alias=post_db --network-alias=comment_db --name mongo_db mongo:latest
docker run -d --network=back_net --network-alias=post --name post isaidashev/post:1.0
docker run -d --network=back_net --network-alias=comment --name comment isaidashev/comment:1.0
docker run -d --network=front_net -p 9292:9292 --name ui isaidashev/ui:2.0
```


Команды:
`sudo ip netns` - просмотр сущетвующих nwt-namespace
`ip netns exec <namespace> <command>` - выполнять команды в выбранном namespace
`docker network connect <network> <container>` - подключить сеть к контейнеру


2. Docker-Compose

* Установка docker-compose

brew install docker-compose

* Собрать образы приложения reddit с помощью docker-compose

Docker-compose поддерживает интерполяцию (подстановку) переменных окружения. `export USERNAME=<your-login>` или использовать файл с расширением `.env`

* Запустить приложение reddit с помощью docker-compose

Запуск
```
docker-compose up -d
```
Список запущенных контейнеров
```
docker-compose ps
```
Для определения названия сети и назначения ip адресов возможности версии  3.5:

```
networks:
  back_net:
    name: back_net
    driver: bridge
    ipam:
      driver: default
      config:
        -
          subnet: 10.0.2.0/24
```

## Задание со *
Название проекта создается на основе названия папки
Название проекта можно задать `docker-compose -p <PROJECT>`



---
HW 16
---

1. Создали bridge-сеть для контейнеров, так как сетевые алиасы не работают в сети по умолчанию
2. Запустили контейнеры в сети
3. Добавили сетевые алиасы к контейнерам

Пример:

`docker run -d --network=reddit --network-alias=comment isaidashev/comment:1.0`

4. Использование volume

Остановить запущенные контейнеры:
`docker kill $(docker ps -q)`

Создать volume:
`docker volume create reddit_db`

Подключить образ через опцию -v:
`docker run -d --network=reddit --network-alias=post_db_new --network-alias=comment_db_new -v reddit_db:/data/db mongo:latest`


## Дополнительное задание:

1. Для изменения сетевого алиаса контейнера использовал опцию `--network-alias=post_db_new`, а для переопределения переменых `-e POST_SERVICE_HOST="post_new"`

Пример:

```
docker run -d --network=reddit --network-alias=post_db_new --network-alias=comment_db_new mongo:latest
docker run -d --network=reddit --network-alias=post_new -e POST_DATABASE_HOST="post_db_new" isaidashev/post:1.0
docker run -d --network=reddit --network-alias=comment_new -e COMMENT_DATABASE_HOST="comment_db_new" isaidashev/comment:1.0
docker run -d --network=reddit -p 9292:9292 -e POST_SERVICE_HOST="post_new" -e COMMENT_SERVICE_HOST="comment_new" isaidashev/ui:1.0
```

2. Попробывал собрать несколько образов используя  ruby:alpine, alpine.

Вывод команды docker image:
```
isaidashev/ui        4.0                 3f8d0a7fe129        7 seconds ago       210MB
isaidashev/ui        3.0                 7566addd4575        2 minutes ago       263MB
isaidashev/ui        2.0                 4330a420f28d        About an hour ago   455MB
```
3. Еще больше размер уменьшить не получилось. Как вариант можно не копировать ruby приложение в образ а собирать его после запуска контейнера.

Пример конфигов:
* .. ui/Dockerfile.alpine
* .. ui/Dockerfile.ruby-alpine

Используя схлопывание `docker export 3e39c97956b49a | docker import - isaidashev/ui:5` удалось пожать образ:

```
isaidashev/ui        5                   536219ce1ed0        10 seconds ago      209MB
isaidashev/ui        4.0                 3f8d0a7fe129        7 seconds ago       210MB
isaidashev/ui        3.0                 7566addd4575        2 minutes ago       263MB
isaidashev/ui        2.0                 4330a420f28d        About an hour ago   455MB
```

---
HW 15
---
1. Создание docker host

* Создал новый проект в GCE docker
`gcloud init` - инициализировать новый проект
`gcloud auth` - войти в профиль google
* Создали докер машин в Google
`docker-machine create --driver google --google-project  docker-181710 --google-zone europe-west1-b --google-machine-type g1-small --google-machine-image $(gcloud compute images list --filter ubuntu-1604-lts --uri)   docker-host
`
Не забыть переключиться на использование удаленной докер машины eval $(docker-machine env docker-host) Не ЗАБЫТЬ ЗАПУСКАТЬ В КАЖДОМ ТЕРМИНАЛЕ!!!

2. Создание своего образа

* В корне проекта созданы файлы:
- Dockerfile - текстовое описание нашего образа
- mongod.conf - преподготовленный конфиг для mongodb
- db_config - переменная с адрессом mongodb
- start.sh - запуск приложения
* `docker build -t reddit:latest .` - cоздание образа -t - это тег.
* `docker run --name reddit -d --network=host reddit:latest` - запуск контейнера

Команды:

`docker images` -a - список всех образов
`docker-machine ls` - список Docker Machine

3. Работа с DockerHub

`docker login` - авторизация в DockerHub
`docker tag reddit:latest <your-login>/otus-reddit:1.0` - определение тега для образа
`docker push <your-login>/otus-reddit:1.0` - выгрузка в DockerHub

---
HW 14
---
Установил докер. Загрузил несколько докер образов и запустил тестовые контейнеры. Изучил команды

## Команды:
1. `docker version` - верси докера
3. `docker ps` - список запущенных контейнеров
4. `docker ps -a` - список контейнеров
5. `docker images` - список образов
6. `docker run имя имя образа` - создание и запуск контейнера из образа. Образ если его нет, будет скачан.
7. `docker create` - создание контейнера из образа. Образ если его нет, будет скачан.
8. `docker run --rm имя имя образа` - контейнер после остановки удалится.
9. `docker run -i имя имя образа` - запускаетконтейнерв foreground режиме (docker attach)
10. `docker run -d имя имя образа` - запускаетконтейнерв background режиме
11. `docker run -t имя имя образа` - создает TTY
12. `docker exec [имя контейнера] [имя процесса]` - запускает новый процесс внутри контейнера
13. `docker commit имя контейнера` - создает образ из запущеного контейнера
14. `docker inspect` - вывод информации о контейнере или образе
15. `docker kill` - безусловная остановка контейнера
16. `docker stop` - остановка контейнера сначала SIGTERM а затем SIGKILL
17. `docker system df` - сколько дискового простантсва занимают контейнеры, образы и volume
18. `docker rm` - удалить контейнер
19. `docker rmi` - удаляет образ
