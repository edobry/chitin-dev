function ociRepoList() {
    requireArg "a registry url" "$1" || return 1
    requireArg "a repository name" "$2" || return 1

    oras repo ls "$1/$2"
}

function ociRepoListTags() {
    requireArg "a registry url" "$1" || return 1
    requireArg "a repository name" "$2" || return 1
    requireArg "an artifact name" "$3" || return 1

    oras repo tags "$1/$2/$3"
}

function ociRepoGetArtifactManifest() {
    requireArg "a registry url" "$1" || return 1
    requireArg "a repository name" "$2" || return 1
    requireArg "an artifact name" "$3" || return 1
    requireArg "a tag" "$4" || return 1

    oras manifest fetch "$1/$2/$3:$4"
}

function ociRepoGetArtifactManifestConfig() {
    requireArg "a registry url" "$1" || return 1
    requireArg "a repository name" "$2" || return 1
    requireArg "an artifact name" "$3" || return 1
    requireArg "a tag" "$4" || return 1

    oras manifest fetch-config "$1/$2/$3:$4"
}
