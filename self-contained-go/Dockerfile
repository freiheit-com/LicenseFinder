FROM golang

# Versioning
ENV PIP_INSTALL_VERSION 10.0.1
ENV MAVEN_VERSION 3.5.3
ENV SBT_VERSION 1.1.1
ENV GRADLE_VERSION 4.10
ENV RUBY_VERSION 2.5.1
ENV MIX_VERSION 1.0
ENV PATH=/usr/local/rvm/bin:$PATH

# COPY LicenseFinder /LicenseFinder

# add persistent go PATH
ADD go.sh /etc/profile.d/go.sh

# programs needed for building
RUN apt-get update \
 && apt-get install -y \
        build-essential \
        curl \
        git-core \
        sudo \
        unzip \
        wget \
        file \
        dirmngr \
        zlib1g-dev \
        libsqlite3-dev \
        ruby-dev \
        rubygems-integration \
# godep is now required for license_finder to work for project that are still managed with GoDep
 && go get github.com/golang/dep/cmd/dep \
# disable gem docs
 && bash -lc "echo 'gem: --no-document' > ~/.gemrc" \
# install bundler
 && bash -lc "gem update --system && \
              gem install bundler -v 1.17.3" \
 && git clone -b "v5.7.1.r1" https://github.com/freiheit-com/LicenseFinder.git /LicenseFinder \
 && bash -lc "cd /LicenseFinder && \
              bundle install -j$(nproc) && \
              rake install" \
 && mkdir /scan \
 && chown 1001 /scan \
# delete caches
 && rm -rf /var/cache/* /usr/local/rvm/src /usr/local/rvm/gems/ruby-$RUBY_VERSION/cache

# include default decisions file
COPY dependency_decisions.yml /dependency_decisions.yml

# include script
COPY checkLicensesGo.sh /checkLicenses.sh

WORKDIR /

USER 1001
CMD cd /scan && /bin/bash -l

# vim: tw=0 ft=dockerfile
