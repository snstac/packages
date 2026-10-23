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

## Repository secret: `PACKAGES_READ_TOKEN`

The publish workflow downloads each product's latest release assets with
`gh release download`. Since most product repos are **private**, the default
`github.token` (scoped to this repo only) can no longer read their releases.
Set the repo secret **`PACKAGES_READ_TOKEN`** to a **fine-grained personal
access token** configured as follows:

| Field | Value |
|---|---|
| Token type | Fine-grained PAT (Settings → Personal access tokens → Tokens → Fine-grained tokens) |
| Repository access | **Only select repositories** — every `owner/repo` in [`products.txt`](products.txt) (38 repos; 31 now private, 7 still public) |
| Expiration | Per org policy (recommend 90 days; renew before expiry) |
| Permissions | **Contents: Read-only** on each selected repo (Metadata: Read-only is always granted) |

`Contents: Read-only` covers reading release metadata and downloading
release assets. The workflow injects it as `GH_TOKEN`; `build-repo.sh` fails
fast with a clear error if the secret is missing. When a repo is added to
`products.txt`, grant the token `Contents: read` on it (or reissue it) or the
daily build will 403 on that repo.

## Signing key

Packages, apt `Release`, and yum `repomd.xml` are signed with the snstac packaging key (RSA-4096, `oss@snstac.com`). The private key exists only in this repo's `GPG_PRIVATE_KEY` Actions secret and in offline backup. Public key: [`snstac.asc`](https://snstac.github.io/packages/snstac.asc).

## Building locally

```sh
sudo apt install reprepro createrepo-c rpm
gpg --import <private key>
KEYID=<keyid> ./build-repo.sh   # builds into site/
```
