#!/bin/bash

# docker build --build-arg PHP_VER=7.4 --build-arg APP_MODE=Laravel -t agusputra/php:7.4 .
# docker build --build-arg PHP_VER=7.4 --build-arg APP_MODE=WP -t agusputra/php:7.4-wp .

# docker build --build-arg PHP_VER=8.0 --build-arg APP_MODE=Laravel -t agusputra/php:8.0 .
# docker build --build-arg PHP_VER=8.0 --build-arg APP_MODE=WP -t agusputra/php:8.0-wp .

# docker build --build-arg PHP_VER=8.1 --build-arg APP_MODE=Laravel -t agusputra/php:8.1 .
# docker build --build-arg PHP_VER=8.1 --build-arg APP_MODE=WP -t agusputra/php:8.1-wp .

# docker build --build-arg PHP_VER=8.2 --build-arg APP_MODE=Laravel -t agusputra/php:8.2 .
# docker build --build-arg PHP_VER=8.2 --build-arg APP_MODE=WP -t agusputra/php:8.2-wp .

###

echo "Starting parallel builds..."

# docker build --build-arg PHP_VER=7.4 --build-arg APP_MODE=Laravel -t agusputra/php:7.4 . &
# docker build --build-arg PHP_VER=7.4 --build-arg APP_MODE=WP -t agusputra/php:7.4-wp . &

# docker build --build-arg PHP_VER=8.0 --build-arg APP_MODE=Laravel -t agusputra/php:8.0 . &
# docker build --build-arg PHP_VER=8.0 --build-arg APP_MODE=WP -t agusputra/php:8.0-wp . &

docker build --build-arg PHP_VER=8.1 --build-arg APP_MODE=Laravel -t agusputra/php:8.1 . &
# docker build --build-arg PHP_VER=8.1 --build-arg APP_MODE=WP -t agusputra/php:8.1-wp . &

# docker build --build-arg PHP_VER=8.2 --build-arg APP_MODE=Laravel -t agusputra/php:8.2 . &
# docker build --build-arg PHP_VER=8.2 --build-arg APP_MODE=WP -t agusputra/php:8.2-wp . &

docker build --build-arg PHP_VER=8.3 --build-arg APP_MODE=Laravel -t agusputra/php:8.3 . &

# Wait for all background processes to finish
wait
