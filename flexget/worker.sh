#!/bin/bash
FLEXGET=/usr/local/bin/flexget
CONFIG=/home/box/flexget/config.yml
TYPE="$1"
FILM=(imdb danske_film hd_film_rapidcows hd_film_unity)
SERIER=(tv dansk_tv tv_substance hd_tv_dbretail)

if [ "$TYPE" == "film" ]; then
    for i in "${FILM[@]}"; do ${FLEXGET} -c ${CONFIG} --cron execute --task "$i"; done
fi

if [ "$TYPE" == "serier" ]; then
    for i in "${SERIER[@]}"; do ${FLEXGET} -c ${CONFIG} --cron execute --task "$i"; done
fi
