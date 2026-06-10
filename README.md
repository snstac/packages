# snstac package repository

Signed **apt** and **yum/dnf** repositories for [snstac](https://github.com/snstac) TAK gateway packages, served from GitHub Pages at **https://snstac.github.io/packages**.

No binaries live in this repo. The [publish workflow](.github/workflows/publish.yml) downloads the latest GitHub Release `.deb`/`.rpm` assets from each repo in [`products.txt`](products.txt), builds the repository trees with `reprepro` and `createrepo_c`, signs everything, and deploys the result as a Pages artifact. It runs on push, daily, and on manual dispatch.

## Using the repos

**Debian / Ubuntu / Raspberry Pi OS:**

```sh
sudo curl -fsSL -o /usr/share/keyrings/snstac.gpg https://snstac.github.io/packages/snstac.gpg
sudo curl -fsSL -o /etc/apt/sources.list.d/snstac.sources https://snstac.github.io/packages/snstac.sources
sudo apt update
sudo apt install lincot cockpit-lincot
```

**Red Hat / Fedora / CentOS Stream / Rocky / Alma:**

```sh
sudo curl -fsSL -o /etc/yum.repos.d/snstac.repo https://snstac.github.io/packages/snstac.repo
sudo dnf install lincot cockpit-lincot
```

## Adding a product

Add its `owner/repo` to `products.txt`. Its latest release must carry versioned `.deb` and/or `.rpm` assets (stable `*latest*` aliases and `.src.rpm` files are ignored). New releases are picked up by the daily run, or immediately via **Actions → publish → Run workflow**.

## Signing key

Packages, apt `Release`, and yum `repomd.xml` are signed with the snstac packaging key (RSA-4096, `oss@snstac.com`). The private key exists only in this repo's `GPG_PRIVATE_KEY` Actions secret and in offline backup. Public key: [`snstac.asc`](https://snstac.github.io/packages/snstac.asc).

## Building locally

```sh
sudo apt install reprepro createrepo-c rpm
gpg --import <private key>
KEYID=<keyid> ./build-repo.sh   # builds into site/
```
