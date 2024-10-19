# checks if the Docke daemon is running, or fails. meant to be used as a failfast
function dockerCheckAndFail() {
    if ! docker version >/dev/null 2>&1; then
        echo "Please start the Docker daemon before rerunning."
        return 1
    fi
}

function dockerBuild() {
    docker build . >&2
    [[ $? -eq 0 ]] || return 1

    dockerGetLatestBuild
}

function dockerGetLatestBuild() {
    docker images -q | head -n 1
}

# deletes all locally-cached Docker images not used in the last day
function dockerPruneImages() {
    docker image prune -a --filter "until=24h"
    docker container prune -f
}

function dockerCheckImageExistsLocal() {
    requireArg "an image name" "$1" || return 1
    requireArg "an image tag" "$2" || return 1

    docker image inspect $1:$2 >/dev/null 2>&1
}
