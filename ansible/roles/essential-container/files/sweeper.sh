#!/bin/bash

set -o nounset
set -o errexit

# default grace period is 7 days
GRACE_PERIOD_SECONDS=${GRACE_PERIOD_SECONDS:=604800}
FORCE_CONTAINER_REMOVAL=${FORCE_CONTAINER_REMOVAL:=0}
REMOVE_ASSOCIATED_VOLUME=${REMOVE_ASSOCIATED_VOLUME:=0}
STATE_DIR=${STATE_DIR:=/var/lib/sweeper}
DOCKER=${DOCKER:=docker}
PID_DIR=${PID_DIR:=/var/run}
DRY_RUN=${DRY_RUN:=0}
PIDFILE=$PID_DIR/sweeper
LOG_TO_SYSLOG=${LOG_TO_SYSLOG:=0}
SYSLOG_FACILITY=${SYSLOG_FACILITY:=user}
SYSLOG_LEVEL=${SYSLOG_LEVEL:=info}
SYSLOG_TAG=${SYSLOG_TAG:=sweeper}

exec 3>>$PIDFILE
if ! flock -x -n 3; then
  echo "[$(date)] : sweeper : Process is already running"
  exit 1
fi

trap "rm -f -- '$PIDFILE'" EXIT

echo $$ > $PIDFILE

function log() {
    msg=$1
    if [[ $LOG_TO_SYSLOG -gt 0 ]]; then
        logger -i -t "$SYSLOG_TAG" -p "$SYSLOG_FACILITY.$SYSLOG_LEVEL" "$msg"
    else
        echo "[$(date +'%Y-%m-%dT%H:%M:%S')] [INFO] : $msg"
    fi
}

function date_parse() {
  if date --utc >/dev/null 2>&1; then
    echo $(date -u --date "${1}" "+%s")
  else
    echo $(date -j -u -f "%F %T" "${1}" "+%s")
  fi
}

# Elapsed time since a docker timestamp, in seconds
function elapsed_time() {
    utcnow=$(date -u "+%s")
    replace_q="${1#\"}"
    without_ms="${replace_q:0:19}"
    replace_t="${without_ms/T/ }"
    epoch=$(date_parse "${replace_t}")
    echo $(($utcnow - $epoch))
}


function container_log() {
    prefix=$1
    filename=$2
    while IFS='' read -r containerid
    do
        log "$prefix $containerid $(${DOCKER} inspect -f {{.Name}} $containerid)"
    done < "$filename"
}

function image_log() {
    prefix=$1
    filename=$2

    while IFS='' read -r imageid
    do
        log "$prefix $imageid $(${DOCKER} inspect -f {{.RepoTags}} $imageid)"
    done < "$filename"
}


# Change into the state directory (and create it if it doesn't exist)
if [ ! -d "$STATE_DIR" ]
then
  mkdir -p $STATE_DIR
fi

cd "$STATE_DIR"

# Verify that docker is reachable
$DOCKER version 1>/dev/null

# List all currently existing containers
$DOCKER ps -a -q --no-trunc | sort | uniq > containers.all

# List running containers
$DOCKER ps -q --no-trunc | sort | uniq > containers.running


# List containers that are not running
comm -23 containers.all containers.running > containers.exited


# Find exited containers that finished at least GRACE_PERIOD_SECONDS ago
> containers.reap
cat containers.exited | while read line
do
    EXITED=$(${DOCKER} inspect -f "{{json .State.FinishedAt}}" ${line})
    ELAPSED=$(elapsed_time $EXITED)
    if [[ $ELAPSED -gt $GRACE_PERIOD_SECONDS ]]; then
        echo $line >> containers.reap
    fi
done


FORCE_CONTAINER_FLAG=""
if [[ $FORCE_CONTAINER_REMOVAL -gt 0 ]]; then
    FORCE_CONTAINER_FLAG="-f"
fi

# Remove associated volume, so that we won't create new orphan volumes.
if [[ $REMOVE_ASSOCIATED_VOLUME -gt 0 ]]; then
    if [[ -z $FORCE_CONTAINER_FLAG ]]; then
        FORCE_CONTAINER_FLAG="-v"
    else
        FORCE_CONTAINER_FLAG=$FORCE_CONTAINER_FLAG"v"
    fi
fi

# remove exited container
if [[ $DRY_RUN -gt 0 ]]; then
    container_log "The following container would have been removed" containers.reap
else
    container_log "Removing containers" containers.reap
    xargs -n 1 $DOCKER rm $FORCE_CONTAINER_FLAG --volumes=true < containers.reap &>/dev/null || true
fi

# Add dangling images to list.
$DOCKER images --no-trunc --format "{{.ID}}" --filter dangling=true > images.reap
if [[ $DRY_RUN -gt 0 ]]; then
    image_log "The following dangling image would have been removed" images.reap
else
    image_log "Removing images" images.reap
    xargs -n 1 $DOCKER rmi < images.reap &>/dev/null || true
fi
