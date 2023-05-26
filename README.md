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
  -n, --dry-run                do not download and print what might be downloaded
  -f, --file NAME              NAME of asset to download (default is all)
  -t, --gitlab-token-env VAR   name for environment VAR with Gitlab token (default "GITLAB_TOKEN")
  -g, --gitlab-url URL         URL of the Gitlab instance (default "https://gitlab.com")
  -h, --help                   help for gitlab-download-release
  -l, --list                   list releases or assets or URL of asset rather than download
  -p, --project PROJECT        PROJECT with releases
  -r, --release RELEASE        RELEASE to download (default is last)
  -O, --to-stdout              send to stdout rather than to file (only single file)
  -v, --version                version for gitlab-download-release
```

## .gitlab-ci.yml

If run in CI then by default `gitlab-download-release` uses GITHUB_TOKEN and
downloads all files from the current project.

Example:

```yaml
stages:
  - download

download:
  stage: download
  image:
    name: dex4er/gitlab-download-release
    entrypoint: [""]
  variables:
    GIT_STRATEGY: none
  script:
    - echo -e "\e[0Ksection_start:`date +%s`:download\r\e[0KDownload"
    - mkdir release
    - cd release
    - gitlab-download-release
    - sha256sum -c checksums.txt
    - echo -e "\e[0Ksection_end:`date +%s`:download\r\e[0K"
  artifacts:
    paths:
      - release/
    expire_in: 1 week
```
