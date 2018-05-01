FROM       superpaintman/mongodb-exporter
MAINTAINER Ildar Saidashev <isaidashev@facebook.com>
EXPOSE     9001

RUN apk add --update ca-certificates

ENTRYPOINT [ "/bin/mongodb_exporter" ]
