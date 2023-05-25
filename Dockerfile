FROM alpine

WORKDIR /usr/local/bin

RUN apk --no-cache add bash

COPY gitlab-download-release .

ENTRYPOINT ["gitlab-download-release"]

LABEL \
  maintainer="Piotr Roszatycki <piotr.roszatycki@gmail.com>" \
  org.opencontainers.image.created=${BUILDDATE} \
  org.opencontainers.image.description="Download release from Gitlab project" \
  org.opencontainers.image.licenses="MIT" \
  org.opencontainers.image.revision=${REVISION} \
  org.opencontainers.image.source=https://github.com/dex4er/gitlab-download-release \
  org.opencontainers.image.title=gitlab-download-release \
  org.opencontainers.image.url=https://github.com/dex4er/gitlab-download-release \
  org.opencontainers.image.vendor=dex4er \
  org.opencontainers.image.version=${VERSION}
