FROM openjdk:11-jre-slim-buster

ENV DB_ADDRESS ""
ENV DB_PORT "5432"
ENV DB_DBNAME ""
ENV DB_USR ""
ENV DB_PWD ""
ENV LB_CMD "--help"

# Install GPG for package vefification
RUN apt-get update \
    && apt-get -y install gnupg wget

# Add the liquibase user and step in the directory
RUN addgroup --gid 1001 liquibase
RUN adduser --disabled-password --uid 1001 --ingroup liquibase liquibase

# Make /liquibase directory and change owner to liquibase
RUN mkdir /liquibase && chown liquibase /liquibase
WORKDIR /liquibase

COPY --chown=liquibase:liquibase ./ /liquibase/

# Change to the liquibase user
USER liquibase

# Latest Liquibase Release Version
ARG LIQUIBASE_VERSION=4.1.1

# Download, verify, extract
ARG LB_SHA256=ef8e0b8f7f0cabc34a61b8a1e7f4feac46652b6f5e62b58a9f2d2cfc98f0033f
RUN set -x \
  && wget -O liquibase-${LIQUIBASE_VERSION}.tar.gz "https://github.com/liquibase/liquibase/releases/download/v${LIQUIBASE_VERSION}/liquibase-${LIQUIBASE_VERSION}.tar.gz" \
  && echo "$LB_SHA256  liquibase-${LIQUIBASE_VERSION}.tar.gz" | sha256sum -c - \
  && tar -xzf liquibase-${LIQUIBASE_VERSION}.tar.gz

# Setup GPG
RUN GNUPGHOME="$(mktemp -d)" 

# Download JDBC libraries, verify
RUN wget -O /liquibase/lib/postgresql.jar https://repo1.maven.org/maven2/org/postgresql/postgresql/42.2.12/postgresql-42.2.12.jar \
    && wget -O /liquibase/lib/postgresql.jar.asc https://repo1.maven.org/maven2/org/postgresql/postgresql/42.2.12/postgresql-42.2.12.jar.asc \
    && gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys 38F47D3E410C47B1 \
    && gpg --batch --verify -fSLo /liquibase/lib/postgresql.jar.asc /liquibase/lib/postgresql.jar

CMD /liquibase/liquibase \
    --changeLogFile=changelog.yaml \
    --driver=org.postgresql.Driver \
    --url=jdbc:postgresql://$DB_ADDRESS:$DB_PORT/$DB_DBNAME \
    --username=$DB_USR \
    --password=$DB_PWD \
    --classpath=dbdrivers/postgresql-42.2.18.jar \
    $LB_CMD
