# Initial Image	
FROM elixir:1.7.4 as builder

ENV SHELL=/bin/bash TERM=xterm

RUN apt-get clean && apt-get update
RUN apt-get install locales -y
ENV LANG=en_US.UTF-8 
RUN echo $LANG UTF-8 > /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=$LANGRUN 

# Dependencies
RUN apt-get install build-essential -y
RUN mix local.hex --force
RUN mix local.rebar --force

# Create folders
RUN mkdir -p /opt/results_provider
RUN mkdir -p /tmp/results_provider

# Copy files
ADD ./config /tmp/results_provider/config
ADD ./protobufs /tmp/results_provider/protobufs
ADD ./rel/config.exs /tmp/results_provider/rel/
ADD ./lib /tmp/results_provider/lib
ADD ./rel/vm.args /tmp/results_provider/rel/
ADD ./mix.exs /tmp/results_provider/

WORKDIR /tmp/results_provider
RUN mix deps.get
RUN MIX_ENV=prod mix deps.compile
RUN MIX_ENV=prod mix compile
RUN MIX_ENV=prod mix release 
RUN tar zxf _build/prod/rel/results_provider/releases/0.1.0/results_provider.tar.gz -C /opt/results_provider
RUN cp rel/vm.args /opt/results_provider/

###############
# Final Image #
###############

FROM debian:stretch-slim

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update
RUN apt-get -qq install -y locales
RUN apt-get -qq install libssl1.1 libssl-dev

# To avoid VM launguage warnings
ENV LANG=en_US.UTF-8 
RUN echo $LANG UTF-8 > /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=$LANGRUN 

RUN mkdir -p /var/log/results_provider
RUN mkdir -p /opt/results_provider
COPY --from=builder /opt/results_provider /opt/results_provider

RUN mkdir /data
ADD ./data/Data.csv /data/

EXPOSE 4000

WORKDIR /opt/results_provider
CMD /opt/results_provider/bin/./results_provider foreground