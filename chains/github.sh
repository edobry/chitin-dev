CHI_GITHUB_API_BASE_URL='https://api.github.com'

function githubGetToken() {
    local secretName=$(chiReadChainnConfigField github secretName)
    chiSecretGet "$secretName"
}

function githubMakeOrgUrl() {
    requireArg 'an organization name' "$1" || return 1

    echo "$CHI_GITHUB_API_BASE_URL/orgs/$1"
}

# lists all known Github teams
function githubListTeams() {
    requireArg 'an organization name' "$1" || return 1

    curl -s -H "Authorization: token $(githubGetToken)" "$(githubMakeOrgUrl $1)/teams?per_page=100" |\
        jq -r '.[] | { slug, id } | "\(.slug) - \(.id)"'
}

# get slug for specified Github teams
# args: team name
function githubGetTeamSlug() {
    requireArg 'an organization name' "$1" || return 1
    requireArg 'a team name' "$2" || return 1

    curl -s -H "Authorization: token $(githubGetToken)" "$(githubMakeOrgUrl $1)/teams/$2" |\
        jq -r '.id'
}

# generates a JWT for Github authentication for the specified app
# args: app id, private key
function githubAppJwt() {
    requireArg 'an app ID' "$1" || return 1
    requireArg 'the private key' "$2" || return 1

    local keyfile=$(tempFile).pem
    echo "$2" > $keyfile
    chmod 600 $keyfile

    jwt encode --secret=@$keyfile --alg RS256 "$(jq -nc --arg appId "$1" '
        {
            "iat": (now | round - 60),
            "exp": (now | round + (5*60)),
            "iss": "\($appId)"
        }')"

    rm $keyfile
}

# validates the signature of the specified JWT
# args: jwt, private key
function jwtValidate() {
    requireArg 'the JWT' "$1" || return 1
    requireArg 'the private key' "$2" || return 1

    local keyfile=$(tempFile).pub
    echo "$2" > $keyfile
    chmod 600 $keyfile

    echo "$1" | jwt decode -j  --iso8601 --alg RS256 --secret=@$keyfile -

    rm $keyfile
}

# creates an installation token for the given Github app installation
# args: app id, installation id, private key
function githubAppCreateInstallationToken() {
    requireArg 'an app ID' "$1" || return 1
    requireArg 'an installation ID' "$2" || return 1
    requireArg 'the private key' "$3" || return 1

    >&2 echo "Generating JWT to authenticate as app $1..."

    local jwt
    jwt=$(githubAppJwt "$1" "$3")
    if [[ $? -ne 0 ]]; then
        >&2 echo "JWT generation failed: $jwt"
        return 1
    fi

    >&2 echo "Creating access token for installation $2..."

    local response=$(curl -s -X POST \
        -H "Authorization: Bearer $jwt" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/app/installations/$2/access_tokens")

    >&2 echo "GH API response: $response"

    echo "$response" | jq -r '.token'
}

# opens the current git repository directory in the Github UI
function githubOpenDirectory() {
    local repoUrl=$(git remote get-url origin | sed 's/\.git//')
    local repoRoot=$(git rev-parse --show-toplevel)
    local currentDir=$(pwd)
    local repoPath=${currentDir#"$repoRoot"}
    local currentBranch=$(git branch --show-current)
    local directoryUrl="$repoUrl/tree/$currentBranch/$repoPath"
    echo "Opening $directoryUrl"
    open "$directoryUrl"
}

function githubClone() {
    requireArg 'a repository name' "$1" || return 1

    pushd $CHI_PROJECT_DIR > /dev/null 2>&1
    git clone git@github.com:$1.git
    cd $1
}

# lists comments on the given issue
# WARNING: not paginated, may need to iteratively re-run
function githubGetIssueComments() {
    requireArg 'a repository name' "$1" || return 1
    requireArg 'an issue number' "$2" || return 1

    curl -s -H "Authorization: token $(githubGetToken)" "$CHI_GITHUB_API_BASE_URL/repos/$1/issues/$2/comments?per_page=100&page=${3:-'1'}"
}

# lists comments on the given issue by a given user
# WARNING: not paginated, may need to iteratively re-run
function githubGetIssueUserComments() {
    requireArg 'a repository name' "$1" || return 1
    requireArg 'an issue number' "$2" || return 1
    requireArg 'a user name' "$3" || return 1

    githubGetIssueComments "$1" "$2" | jq --arg user "$3" '.[] | select(.user.login = "$user").id' "$4"
}

# deletes a comment on the given issue
function githubDeleteIssueComment() {
    requireArg 'a repository name' "$1" || return 1
    requireArg 'a comment number' "$2" || return 1

    curl -X DELETE -s -H "Authorization: token $(githubGetToken)" "$CHI_GITHUB_API_BASE_URL/repos/$1/issues/comments/$2"
}

# deletes a comment on the given issue
# WARNING: not paginated, may need to iteratively re-run
function githubDeleteUserIssueComments() {
    requireArg 'a repository name' "$1" || return 1
    requireArg 'an issue number' "$2" || return 1
    requireArg 'a user name' "$3" || return 1

    echo "Deleting comments on issue $1#$2 by user $3..."
    while IFS= read -r id; do
        githubDeleteIssueComment "$1" "$id"
    done <<< $(githubGetIssueUserComments "$1" "$2" "$3" "$4")
}
