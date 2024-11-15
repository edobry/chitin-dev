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

function dockerGetCredentials() {
    requireArg "a registry" "$1" || return 1

    echo "$1" | docker-credential-osxkeychain get
}

function dockerCurl() {
    requireArg "a registry domain" "$1" || return 1
    requireArg "a url path" "$2" || return 1

    local creds="$(dockerGetCredentials "$1")"
    local username=$(jsonReadPath "$creds" Username)
    local secret=$(jsonReadPath "$creds" Secret)

    local auth="$([[ "$username" == "oauth2accesstoken" ]] \
        && echo "-H 'Authorization: Bearer $secret'" \
        || echo "-u $username:$secret")"

    curl -s "$auth" "https://$1/v2/$2"
}

function dockerCurlListTags() {
    requireArg "a registry domain" "$1" || return 1
    requireArg "a repository name" "$2" || return 1
    requireArg "an artifact name" "$3" || return 1

    dockerCurl "$1" "$2/$3/tags/list" "$4:$5"
}
