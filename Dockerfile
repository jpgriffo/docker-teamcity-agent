FROM selenium/standalone-chrome
MAINTAINER Javi Perez-Griffo "javier.perez-griffo@ingrammicro.com"

ENV RUBY_VERSION 2.2
ENV GOLANG_VERSION 1.7
ENV MONGO_VERSION 2.8.0-rc4
ENV REDIS_VERSION 2.8.19
ENV NODEJS_VERSION 6.9.1
ENV PHANTOMJS_VERSION 2.1.1

USER root

####
# Standard Development Libraries
####
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y  git \
 				build-essential locate libstdc++6  curl sudo wget vim tzdata \
				libcurl4-openssl-dev zlib1g-dev  libffi-dev libssl-dev libreadline-dev \
				libyaml-dev libxml2-dev libxslt-dev gawk libsqlite3-dev sqlite3 \
				autoconf libgmp-dev libgdbm-dev libncurses5-dev automake libtool \
				bison pkg-config libgmp-dev libfontconfig1

####
# Mongo
####
RUN curl -SL "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-$MONGO_VERSION.tgz" -o mongo.tgz && \
			  curl -SL "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-$MONGO_VERSION.tgz.sig" -o mongo.tgz.sig && \
			  tar -xvf mongo.tgz -C /usr/local --strip-components=1 && \
			  rm mongo.tgz* && \
				mkdir -p /data/db

####
# Redis
####
RUN mkdir -p /usr/src/redis && \
        curl -sSL "http://download.redis.io/releases/redis-$REDIS_VERSION.tar.gz" -o redis.tar.gz && \
        tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1 && \
        rm redis.tar.gz && \
        make -C /usr/src/redis && \
        make -C /usr/src/redis install && \
        rm -r /usr/src/redis && \
				mkdir -p /data/redis

####
# Ruby
####
RUN curl -L https://get.rvm.io | bash -s stable && \
			/bin/bash -l -c "rvm requirements" && \
			/bin/bash -l -c "rvm install $RUBY_VERSION" && \
			/bin/bash -l -c "gem install bundler --no-ri --no-rdoc" && \
			/bin/bash -l -c "rvm --default use $RUBY_VERSION" && \
			rm -rf /var/lib/apt/lists/* /var/cache/apt/*

####
# Golang
####
RUN curl -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer  | bash -s  && \
      /bin/bash -l -c "source /root/.gvm/scripts/gvm && gvm install go1.4 --binary && gvm use go1.4 && export GOROOT_BOOTSTRAP=$GOROOT && gvm install go$GOLANG_VERSION --binary && gvm use go$GOLANG_VERSION --default" && \
      mkdir -p /home/golang/src/github.com/ingrammicro && \
      mkdir -p /home/golang/bin && \
      /bin/bash -l -c "source /root/.gvm/scripts/gvm && export GOPATH=\"/home/golang/\" && go get -u github.com/rancher/trash gopkg.in/cucumber/gherkin-go.v3 github.com/DATA-DOG/godog/cmd/godog github.com/golang/dep/cmd/dep"


####
# Nodejs
####
run curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash && \
  export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
  nvm install $NODEJS_VERSION && nvm install 4.2.6 && nvm alias default 4.2.6 && \
  npm install -g coffee-script

####
# Phantomjs
####
RUN mkdir /tmp/phantomjs && \
  curl -L https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2 \
        | tar -xj --strip-components=1 -C /tmp/phantomjs && \
  mv /tmp/phantomjs/bin/phantomjs /usr/local/bin && rm -rf /tmp/*


VOLUME  ["/root/.ssh"]

EXPOSE 9090

ADD docker-entrypoint.sh /entrypoint.sh
ADD setup-agent.sh /setup-agent.sh
ADD redis.conf /etc/redis.conf
ADD go.sh /etc/profile.d/go.sh
ADD nvm.sh /etc/profile.d/nvm.sh

ENTRYPOINT ["/entrypoint.sh"]
