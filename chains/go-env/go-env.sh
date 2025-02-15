if ! isMacOS; then
    export GOROOT="$(dirname $(which go))"
    chiToolsAddDirToPath "$GOROOT/bin"
else
    chiToolsAddDirToPath "~/go/bin"
fi
