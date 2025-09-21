#!/bin/bash

LOCAL_VERSION=""
REPO_VERSION=""
LOCAL_FORMATTED_VERSION=""
REPO_FORMATTED_VERSION=""


# format version AA.B.C.DD to AABBCCDD
getformattedversion() {
    version=$1
    IFS='.-' read -r -a parts <<< "$version"
    formatted_version=$(printf "%d%02d%02d%02d" "${parts[0]:-0}" "${parts[1]:-0}" "${parts[2]:-0}" "${parts[3]:-0}")
    echo "$formatted_version"
}

# get formatted version from PKGBUILD
getlocalversion() {
    version=$(cat .SRCINFO | grep 'pkgver = ' | cut -d '=' -f 2 | sed "s/_/-/" | sed "s/ //")
    echo "$version"
}

# get formatted version from repo
getrepoversion() {
    html=$(curl -ks "https://api.github.com/repos/Mintplex-Labs/anything-llm/releases/latest")
    version=$(echo $html | sed -E 's/.*"tag_name": "v([^"]+)".*/\1/')
    echo "$version"
}

updatelocalrepo() {
    pkgversion=$(echo "$REPO_VERSION" | sed "s/-/_/")
    sed -i "s/$LOCAL_VERSION/$REPO_VERSION/g" PKGBUILD
    sed -i "s/^_pkgver=.*/_pkgver=$REPO_VERSION/" PKGBUILD
    sed -i "s/^pkgver=.*/pkgver=$pkgversion/" PKGBUILD
    sed -i "s/^sha256sums=.*/sha256sums=\(\""$sha256"\"\)/" PKGBUILD
    sed -i "s/$LOCAL_VERSION/$REPO_VERSION/g" .SRCINFO
    sed -i "s/pkgver = .*/pkgver = $pkgversion/" .SRCINFO
    sed -i "s/sha256sums = .*/sha256sums = "$sha256"/" .SRCINFO
}

LOCAL_VERSION=$(getlocalversion)
REPO_VERSION=$(getrepoversion)
LOCAL_FORMATTED_VERSION=$(getformattedversion $LOCAL_VERSION)
REPO_FORMATTED_VERSION=$(getformattedversion $REPO_VERSION)
echo "Local version: $LOCAL_VERSION"
echo "Repo version: $REPO_VERSION"
echo "Local formatted version: $LOCAL_FORMATTED_VERSION"
echo "Repo formatted version: $REPO_FORMATTED_VERSION"

if (($LOCAL_FORMATTED_VERSION < $REPO_FORMATTED_VERSION)); then
    echo "New version detected. Updating local repo ..."
    updatelocalrepo
    echo "REPO_VERSION=$REPO_VERSION" >> "$GITHUB_OUTPUT"
else
    echo "No new version detected."
fi
