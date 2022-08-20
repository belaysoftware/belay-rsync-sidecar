FROM alpine:latest

RUN apk add --update --no-cache git rsync openssh-client

WORKDIR /root
ADD gitconfig /root/.gitconfig
ADD run.sh /root/

ENTRYPOINT [ "/root/run.sh" ]