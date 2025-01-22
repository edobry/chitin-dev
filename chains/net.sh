# downloads a file from a url and checksums it
# args: url to file
function checksumUrl() {
    requireArg "a URL" "$1" || return 1

    local url="$1"
    local tempFileName=$(tempFile)

    curl $url -L --output $tempFileName -s
    shasum -a 256 $tempFileName | awk '{ print $1 }'
    rm $tempFileName
}

function netTest() {
    requireArg "a URL" "$1" || return 1
    requireArg "a port" "$2" || return 1

    echo 'QUIT' | netcatTimeout 5 "$1" "$2" >/dev/null
}

function netTailscaleCurrentNetwork() {
    tailscale status --json | jq -r '.CurrentTailnet.Name'
}
function netTailscaleIsUp() {
    [[ $(tailscale status --json | jq -r '.BackendState') == "Running" ]]
}

function netTailscaleSwitchAccount() {
    requireArg "an account email" "$1" || return 1

    tailscale switch "$1"
}

function netFreePort() {
    requireArg "a port number" "$1" || return 1

    kill $(lsof -t -i ":$1")
}
