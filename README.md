## Build
```
docker build --build-arg APP_VER=7.4 --build-arg APP_MODE=Laravel -t agusputra/php:7.4 .
docker build --build-arg APP_VER=7.4 --build-arg APP_MODE=WP -t agusputra/php:7.4-wp .

docker build --build-arg APP_VER=8.2 --build-arg APP_MODE=Laravel -t agusputra/php:8.2 .
docker build --build-arg APP_VER=8.2 --build-arg APP_MODE=WP -t agusputra/php:8.2-wp .
```

## Run
```
docker run --name app-server -v app-server:/home/user1/code -p 7001:80 -d agusputra/php:8.2
docker run --name wp -v wp:/home/user1/code -p 7001:80 -d agusputra/php:8.2-wp

docker run --rm -it -v ${PWD}/code:/home/user1/code agusputra/php:8.2 composer create-project laravel/laravel code
```