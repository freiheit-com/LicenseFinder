#!/bin/bash

set -eu

DOCKER_IMAGE=${DOCKER_IMAGE:?Set this in either the source file or an environment variable}
VAULT_PATH=

usage() {
    echo "usage: $0 [options] [cmd [args]] [-- [docker-create-args]]"
    echo "OPTIONS:"
    echo "    --vault             copy dependency_decisions.yml from vault"
    echo "    --container         use dependency_decisions.yml already in container"
    echo "    docker-create-args  docker create is called with -it + these args"
    echo
    echo "EXAMPLES:"
    echo "    $0 checkLicenses.sh -- --interactive=false  # override -i but not -t"
    echo "    $0 checkLicenses.sh license_finder report   # run license_finder report on project"
    echo "    $0 checkLicenses.sh bash -l                 # explore with bash"
}

cleanup() {
    if [[ -v CONTAINER && -n "$CONTAINER" ]]; then
        docker rm $CONTAINER >/dev/null
    fi

    if [ -v DOCDIR ]; then
        rm -rf "$DOCDIR"
    fi
}

trap cleanup EXIT

cmd=
decisions=
license_finder_args=
dockerargs="-it"

whoseargs=""
while [ "$#" -gt 0 ]; do
    if [ "$1" = -- ]; then
        whoseargs="docker"
        shift
        continue
    fi

    if [ -z "$whoseargs" ]; then
        case "$1" in
        --vault)
            : ${VAULT_PATH:?Set this in either the source file or an environment variable}
            decisions=vault
            shift
            continue
            ;;
        --container)
            decisions=container
            shift
            continue
            ;;
        -h | --help)
            usage
            exit 1
            ;;
        *)
            whoseargs="cmd"
            cmd="$1"
            shift
            continue
            ;;
        esac
    fi

    if [ "$whoseargs" = "cmd" ]; then
        cmd+=" $(printf %q "$1")"
    # or parse script args
    elif [ "$whoseargs" = "docker" ]; then
        dockerargs+=" $(printf %q "$1")"
    fi
    shift
done

which docker > /dev/null || {
  echo "You do not have docker installed. Please install it:"
  echo "    https://docs.docker.com/engine/installation/"
  exit 1
}

if [ "$decisions" = vault ]; then
    DOCDIR="$(mktemp -p . -d 'doc.XXX')"
    chmod +rwx "$DOCDIR"
    if [ -z "$cmd" ]; then
        license_finder_args="'--decisions_file=$DOCDIR/dependency_decisions.yml'"
    fi
    vault read -field=default "$VAULT_PATH" > "$DOCDIR"/dependency_decisions.yml
elif [ "$decisions" = container ]; then
    license_finder_args="'--decisions_file=/dependency_decisions.yml'"
fi

if [ -z "$cmd" ]; then
    cmd="license_finder $license_finder_args"
fi
CONTAINER=$(eval docker create $dockerargs "${DOCKER_IMAGE:?please}" '/bin/bash -lc "cd /scan && $cmd"')

# copy contents (excluding .git) one by one
if [ -O . ]; then
    find -maxdepth 1 -not -path ./.git -exec docker cp {} $CONTAINER:/scan/ \;
else
    echo "Cannot safely copy current directory over to docker container"
fi

docker start -ai $CONTAINER || {
    echo "Could not approve licenses in the project"
    exit 1
}

# EXIT trap removes docker container
