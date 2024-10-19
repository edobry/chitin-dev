# chitin - dev

This repository is a [chitin fiber](https://github.com/edobry/chitin#structure) containing a collection of chains for software development.

## Dependencies

Optionally required:

- `docker`
- `jwt`

## Setup

1. Install the dependencies for the chains(s) you want to use (see docs below)
2. Clone this repository to your `project dir` (the directory where you usually run `git clone`)
3. Register this fiber with `chitin` [TBD]

## Chains

### Docker

Functions:

- `pruneDockerImages`: deletes all locally-cached Docker images not used in the last day
- `listDockerImageTags`: lists all available tags for a Docker image
- `getLatestDockerImageTag`: gets the latest available tag for a Docker image
- `getDockerImageTags`: gets a human-readable view of available tags for a Docker image
- `dockerArtifactoryPublish`: tags and pushes a locally-built Docker image to Artifactory
- `dockerArtifactoryPublishLast`: tags and pushes the last locally-built Docker image to Artifactory

### Github

#### Configuration

This chain leverages `chiSecret` for managing the Github PAT; add a section to your chiConfig with the name of the secret to use:

```json
{
  "chains": {
    "github": {
      "secretName": "gh-pat"
    }
  }
}
```

Functions:

- `githubListTeams`: lists all known Github teams
- `githubAppJwt`: generates a JWT for Github authentication for the specified app
- `jwtValidate`: validates the signature of the specified JWT
- `githubAppCreateInstallationToken`: creates an installation token for the given Github app installation
- `githubOpenDirectory`: opens the current git repository directory in the Github UI

### SSH

Functions:

- `sshTunnel`: sets up an SSH tunnel to forward from a local port

### Network

Functions:

- `checksumUrl`: downloads a file from a url and checksums it
