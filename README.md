# gitlab-download-release

[![GitHub](https://img.shields.io/github/v/tag/dex4er/gitlab-download-release?label=GitHub)](https://github.com/dex4er/gitlab-download-release)
[![Docker](https://github.com/dex4er/gitlab-download-release/actions/workflows/docker.yaml/badge.svg)](https://github.com/dex4er/gitlab-download-release/actions/workflows/docker.yaml)
[![Trunk Check](https://github.com/dex4er/gitlab-download-release/actions/workflows/trunk.yaml/badge.svg)](https://github.com/dex4er/gitlab-download-release/actions/workflows/trunk.yaml)
[![Docker Image Version](https://img.shields.io/docker/v/dex4er/gitlab-download-release/latest?label=docker&logo=docker)](https://hub.docker.com/r/dex4er/gitlab-download-release)

Download release from Gitlab project

## Usage

```console
gitlab-download-release [flags]
```

### Options

```console
  -d, --download NAME          NAME of asset to download (default is all)
  -t, --gitlab-token-env VAR   name for environment VAR with Gitlab token (default "GITLAB_TOKEN")
  -g, --gitlab-url URL         URL of the Gitlab instance (default "https://gitlab.com")
  -h, --help                   help for gitlab-download-release
  -l, --list                   List releases or assets rather than download
  -p, --project PROJECT        PROJECT with releases
  -r, --release RELEASE        RELEASE to download (default is last)
  -v, --version                version for gitlab-download-release
```
