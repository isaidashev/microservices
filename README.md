___
HW 16
___

* Образ для сервисного приложения
* Оптимизация работы докер образа
* Запуск работы приложения на основе Докер образов
* Разбить приложение на несколько компонент

* Разбить наше приложение на несколько компонент
* Запустить наше микросервисное приложение

1. Создали bridge-сеть для контейнеров, так как сетевые алиасы не работают в сети по умолчанию
2. Запустили контейнеры в сети
3. Добавили сетевые контейнеры контейнерам

Пример:

`docker run -d --network=reddit --network-alias=comment isaidashev/comment:1.0`


## Дополнительное задание:

Для изменения сетевого алиаса контейнера использовал опцию `--network-alias=post_db_new`, а для переопределения переменых `-e POST_SERVICE_HOST="post_new"`

Пример:

`docker run -d --network=reddit --network-alias=post_db_new --network-alias=comment_db_new mongo:latest
docker run -d --network=reddit --network-alias=post_new -e POST_DATABASE_HOST="post_db_new" isaidashev/post:1.0
docker run -d --network=reddit --network-alias=comment_new -e COMMENT_DATABASE_HOST="comment_db_new" isaidashev/comment:1.0
docker run -d --network=reddit -p 9292:9292 -e POST_SERVICE_HOST="post_new" -e COMMENT_SERVICE_HOST="comment_new" isaidashev/ui:1.0`

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
