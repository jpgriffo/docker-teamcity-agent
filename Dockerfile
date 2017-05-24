FROM selenium/standalone-chrome
MAINTAINER Javi Perez-Griffo "javier.perez-griffo@ingrammicro.com"

ENV RUBY_VERSION 2.2
ENV GOLANG_VERSION 1.7
ENV MONGO_VERSION 2.8.0-rc4
ENV REDIS_VERSION 2.8.19

USER root

####
# Standard Development Libraries
####
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y  git \
 				build-essential locate libstdc++6  curl sudo wget vim tzdata \
				libcurl4-openssl-dev zlib1g-dev  libffi-dev libssl-dev libreadline-dev \
				libyaml-dev libxml2-dev libxslt-dev gawk libsqlite3-dev sqlite3 \
				autoconf libgmp-dev libgdbm-dev libncurses5-dev automake libtool \
				bison pkg-config libgmp-dev

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
# NodeJS
####
RUN curl -sL https://deb.nodesource.com/setup | bash - && \
		  apt-get install -y nodejs npm && \
		  apt-get clean && \
		  rm -rf /var/lib/apt/lists/*

####
# Ruby
####
RUN curl -L https://get.rvm.io | bash -s stable && \
			/bin/bash -l -c "rvm requirements" && \
			/bin/bash -l -c "rvm install $RUBY_VERSION" && \
			/bin/bash -l -c "gem install bundler --no-ri --no-rdoc" && \
			/bin/bash -l -c "rvm --default use $RUBY_VERSION" && \
			rm -rf /var/lib/apt/lists/* /var/cache/apt/* && \
			echo ". /etc/profile.d/rvm.sh" >> /root/.bashrc

####
# Golang
####
RUN curl -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer  | bash -s  && \
      /bin/bash -l -c "source /root/.gvm/scripts/gvm && gvm install go1.4 -B && gvm use go1.4 && export GOROOT_BOOTSTRAP=$GOROOT && gvm install go$GOLANG_VERSION && gvm use go$GOLANG_VERSION --default" && \
      echo ". /root/.gvm/scripts/gvm" >> /root/.bashrc

VOLUME  ["/root/.ssh"]

EXPOSE 9090

ADD docker-entrypoint.sh /entrypoint.sh
ADD setup-agent.sh /setup-agent.sh
ADD redis.conf /etc/redis.conf

ENTRYPOINT ["/entrypoint.sh"]
