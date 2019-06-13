FROM selenium/standalone-chrome
MAINTAINER Javi Perez-Griffo "javier.perez-griffo@ingrammicro.com"

ENV RUBY_VERSION 2.5
ENV GOLANG_VERSION 1.11.5
ENV MONGO_VERSION 3.6.12 
ENV REDIS_VERSION 5.0.5
ENV NODEJS_VERSION 8.9.4
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
RUN command curl -sSL https://rvm.io/pkuczynski.asc | gpg --import - && curl -L https://get.rvm.io | bash -s stable && \
			/bin/bash -l -c "rvm requirements" && \
			/bin/bash -l -c "rvm install $RUBY_VERSION" && \
			/bin/bash -l -c "gem install bundler --no-document" && \
			/bin/bash -l -c "rvm --default use $RUBY_VERSION" && \
			rm -rf /var/lib/apt/lists/* /var/cache/apt/* && \
			echo ". /etc/profile.d/rvm.sh" >> /root/.bashrc

####
# Golang
####
RUN curl -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer  | bash -s  && \
      /bin/bash -l -c "source /root/.gvm/scripts/gvm && gvm install go$GOLANG_VERSION --binary && gvm use go$GOLANG_VERSION --default" && export GOROOT_BOOTSTRAP=$GOROOT && \
      echo ". /root/.gvm/scripts/gvm" >> /root/.bashrc && \
      mkdir -p /home/golang/src/github.com/ingrammicro && \
      mkdir -p /home/golang/bin && \
      echo "export GOPATH=\"/home/golang/\"" >> /root/.bashrc && \
      echo "export PATH=\"\$PATH:/home/golang/bin\"" >> /root/.bashrc && \
      /bin/bash -l -c "source /root/.gvm/scripts/gvm && export GOPATH=\"/home/golang/\" && go get -u github.com/rancher/trash gopkg.in/cucumber/gherkin-go.v3 github.com/DATA-DOG/godog/cmd/godog github.com/golang/dep/cmd/dep"


####
# Nodejs
####
run curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash && \
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

####
# Kitchen.
####
#ADD set_name_of_domain.patch /set_name_of_domain.patch
#RUN curl -Lo chefdk.deb https://packages.chef.io/files/stable/chefdk/2.3.1/ubuntu/16.04/chefdk_2.3.1-1_amd64.deb && \
#dpkg -i chefdk.deb && rm chefdk.deb && \
#curl -Lo vagrant.deb https://releases.hashicorp.com/vagrant/1.9.8/vagrant_1.9.8_x86_64.deb && \
#dpkg -i vagrant.deb && rm vagrant.deb && \
#apt update && \
#apt install -y libvirt-dev && \
#rm -rf /var/lib/apt/lists/* /var/cache/apt/* && \
#vagrant plugin install vagrant-libvirt && \
#patch /root/.vagrant.d/gems/2.3.4/gems/vagrant-libvirt-0.0.40/lib/vagrant-libvirt/action/set_name_of_domain.rb < /set_name_of_domain.patch



VOLUME  ["/root/.ssh"]

EXPOSE 9090

COPY docker-entrypoint.sh /entrypoint.sh
COPY setup-agent.sh /setup-agent.sh
COPY redis.conf /etc/redis.conf
#COPY buildAgent.zip /buildAgent.zip
#RUN mkdir /root/agent && cd /root/agent && unzip /buildAgent.zip && rm /buildAgent.zip

ENTRYPOINT ["/entrypoint.sh"]
