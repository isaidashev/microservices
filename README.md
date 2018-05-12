---
HW 24
---
* Сбор не структурированых логов
* Визуализация логов
* Сбор структурированных логов

* Сбор логов с Docker контейнеров

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
