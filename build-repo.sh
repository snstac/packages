#!/bin/bash
# Build the snstac apt + yum repositories into site/ from the latest GitHub
# Release assets of each repo listed in products.txt.
#
# Requirements: gh (authenticated), gpg (signing key imported), reprepro,
# createrepo_c, rpmsign. Set KEYID to the signing key fingerprint/ID.
#
# Usage: KEYID=4F0D93E47D24D367 ./build-repo.sh
set -euo pipefail

cd "$(dirname "$0")"

: "${KEYID:?set KEYID to the GPG signing key id}"
BASE_URL="${BASE_URL:-https://snstac.github.io/packages}"

rm -rf work site
mkdir -p work site

echo "==> Downloading latest release assets"
grep -v '^\s*#' products.txt | grep -v '^\s*$' | while read -r repo; do
    echo "  - $repo"
    gh release download --repo "$repo" --dir work --clobber \
        --pattern '*.deb' --pattern '*.rpm'
done
# Drop stable-name aliases (duplicates of the versioned files) and src rpms.
rm -f work/*latest* work/*.src.rpm
ls -l work/

#
# apt repository (reprepro)
#
echo "==> Building apt repository"
mkdir -p site/apt/conf
cat > site/apt/conf/distributions <<EOF
Origin: snstac
Label: snstac
Codename: stable
Suite: stable
Architectures: amd64 arm64 armhf
Components: main
Description: Sensors & Signals LLC package repository
SignWith: ${KEYID}
EOF
reprepro -b site/apt includedeb stable work/*.deb
reprepro -b site/apt list stable

#
# yum/dnf repository (createrepo_c), packages and metadata both signed
#
echo "==> Building yum repository"
echo "%_gpg_name ${KEYID}" > ~/.rpmmacros
rpmsign --addsign work/*.rpm
mkdir -p site/rpm
cp work/*.rpm site/rpm/
createrepo_c --general-compress-type=gz site/rpm
gpg --batch --yes --detach-sign --armor site/rpm/repodata/repomd.xml

#
# public key + client config files
#
echo "==> Writing keys and client config"
gpg --export "${KEYID}" > site/snstac.gpg
gpg --armor --export "${KEYID}" > site/snstac.asc

cat > site/snstac.sources <<EOF
Types: deb
URIs: ${BASE_URL}/apt
Suites: stable
Components: main
Signed-By: /usr/share/keyrings/snstac.gpg
EOF

cat > site/snstac.repo <<EOF
[snstac]
name=Sensors \& Signals LLC
baseurl=${BASE_URL}/rpm
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=${BASE_URL}/snstac.asc
EOF

# Pages: no Jekyll processing
touch site/.nojekyll

#
# index page
#
PKG_LIST=$(reprepro -b site/apt list stable | awk '{print "<li><code>" $2 " " $3 "</code></li>"}' | sort -u)
cat > site/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Sensors &amp; Signals LLC Package Repository</title>
<style>
body { font-family: system-ui, sans-serif; max-width: 46rem; margin: 2rem auto; padding: 0 1rem; color: #222; }
pre { background: #f4f4f4; padding: .8rem; overflow-x: auto; border-radius: 4px; }
code { background: #f4f4f4; padding: 0 .2rem; }
</style>
</head>
<body>
<h1>Sensors &amp; Signals LLC Package Repository</h1>
<p>Signed apt and yum/dnf repositories for <a href="https://github.com/snstac">snstac</a> TAK gateway packages.
Rebuilt automatically from the latest GitHub Releases.</p>

<h2>Debian / Ubuntu / Raspberry Pi OS</h2>
<pre>sudo curl -fsSL -o /usr/share/keyrings/snstac.gpg ${BASE_URL}/snstac.gpg
sudo curl -fsSL -o /etc/apt/sources.list.d/snstac.sources ${BASE_URL}/snstac.sources
sudo apt update
sudo apt install lincot cockpit-lincot</pre>

<h2>Red Hat / Fedora / CentOS Stream / Rocky / Alma</h2>
<pre>sudo curl -fsSL -o /etc/yum.repos.d/snstac.repo ${BASE_URL}/snstac.repo
sudo dnf install lincot cockpit-lincot</pre>

<h2>Packages</h2>
<ul>
${PKG_LIST}
</ul>

<p>Signing key fingerprint: <code>$(gpg --fingerprint "${KEYID}" | sed -n 2p | tr -d ' ')</code><br>
Source: <a href="https://github.com/snstac/packages">snstac/packages</a></p>
</body>
</html>
EOF

echo "==> Done; site/ ready to deploy"
du -sh site
