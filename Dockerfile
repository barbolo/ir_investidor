FROM ruby:2.5.3

RUN apt-get update -qq && apt-get install -y build-essential

# Update time zone
RUN ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
RUN dpkg-reconfigure -f noninteractive tzdata

# for a JS runtime
RUN apt-get install -y nodejs

# for mysql
RUN apt-get install -y mysql-client default-libmysqlclient-dev

# for nokogiri
RUN apt-get install -y zlib1g-dev liblzma-dev

# for pdftohtml
RUN apt-get install -y -q --no-install-recommends poppler-utils

# add app directory
ENV APP_HOME /ir_investidor
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

# bundle gems in a separate volume
ENV BUNDLE_GEMFILE=$APP_HOME/Gemfile BUNDLE_JOBS="$(nproc)" BUNDLE_PATH=/bundle

# Add application binaries paths to PATH
ENV PATH $APP_HOME/bin:$BUNDLE_PATH/bin:$PATH

ADD . $APP_HOME
