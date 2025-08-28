FROM ruby:3.4

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y curl wget git procps && \
    gem update --system && \
    gem update bundler && \
    # Add unprivileged user
    groupadd --gid $USER_GID $USERNAME && \
    useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME && \
    # Cleaning up
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

COPY ./docker-entrypoint.sh /

USER $USERNAME
ENV GEM_HOME="/home/$USERNAME/.gem/ruby/$RUBY_VERSION"
ENV PATH=$GEM_HOME/bin:$GEM_HOME/gems/bin:$PATH
RUN mkdir -p $GEM_HOME

ENTRYPOINT ["/docker-entrypoint.sh"]
