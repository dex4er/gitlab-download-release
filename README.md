# gitlab-download-release

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
