FROM buildpack-deps:focal as builder

LABEL maintainer="prabhu" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.vendor="prabhus" \
      org.label-schema.name="scan-ide" \
      org.label-schema.version=$CLI_VERSION \
      org.label-schema.license="GPL-3.0-or-later" \
      org.label-schema.description="gitpod workspace image with shiftleft-scan built-in" \
      org.label-schema.url="" \
      org.label-schema.usage="https://github.com/prabhu/scan-ide" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/prabhu/scan-ide.git" \
      org.label-schema.docker.cmd="docker run --rm -it --name scan-ide prabhus/scan-ide"

### base ###
RUN yes | unminimize \
    && apt-get install -yq \
        zip \
        unzip \
        bash-completion \
        build-essential \
        htop \
        jq \
        less \
        locales \
        man-db \
        nano \
        software-properties-common \
        sudo \
        time \
        vim \
        multitail \
        lsof \
        python3 \
        python3-pip \
        python3-dev \
        libssl1.1 libkrb5-3 zlib1g \
        libicu66 \
        openjdk-8-jre-headless \
        openjdk-11-jre-headless \
        maven \
        gradle \
    && locale-gen en_US.UTF-8 \
    && mkdir /var/lib/apt/dazzle-marks \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

ENV LANG=en_US.UTF-8

### Git ###
RUN add-apt-repository -y ppa:git-core/ppa \
    && apt-get install -yq git \
    && rm -rf /var/lib/apt/lists/*

### Gitpod user ###
# '-l': see https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#user
RUN useradd -l -u 33333 -G sudo -md /home/gitpod -s /bin/bash -p gitpod gitpod \
    # passwordless sudo for users in the 'sudo' group
    && sed -i.bkp -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers
ENV HOME=/home/gitpod
WORKDIR $HOME
# custom Bash prompt
RUN { echo && echo "PS1='\[\e]0;\u \w\a\]\[\033[01;32m\]\u\[\033[00m\] \[\033[01;34m\]\w\[\033[00m\] \\\$ '" ; } >> .bashrc

### Gitpod user (2) ###
USER gitpod
# use sudo so that user does not get sudo usage info on (the first) login
RUN sudo echo "Running 'sudo' for Gitpod: success" && \
    # create .bashrc.d folder and source it in the bashrc
    mkdir /home/gitpod/.bashrc.d && \
    (echo; echo "for i in \$(ls \$HOME/.bashrc.d/*); do source \$i; done"; echo) >> /home/gitpod/.bashrc

### Install C/C++ compiler and associated tools ###
LABEL dazzle/layer=lang-c
LABEL dazzle/test=tests/lang-c.yaml
USER root
RUN curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - \
    && echo "deb https://apt.llvm.org/focal/ llvm-toolchain-focal main" >> /etc/apt/sources.list.d/llvm.list \
    && apt-get update \
    && apt-get install -yq \
        clang-format \
        clang-tidy \
        # clang-tools \ # breaks the build atm
        clangd \
        gdb \
        lld \
    && cp /var/lib/dpkg/status /var/lib/apt/dazzle-marks/lang-c.status \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*


### Homebrew ###
LABEL dazzle/layer=tool-brew
LABEL dazzle/test=tests/tool-brew.yaml
USER gitpod
RUN mkdir ~/.cache && sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"
ENV PATH="$PATH:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin/" \
    MANPATH="$MANPATH:/home/linuxbrew/.linuxbrew/share/man" \
    INFOPATH="$INFOPATH:/home/linuxbrew/.linuxbrew/share/info" \
    HOMEBREW_NO_AUTO_UPDATE=1
RUN sudo apt-get remove -y cmake \
    && brew install cmake

### Go ###
LABEL dazzle/layer=lang-go
LABEL dazzle/test=tests/lang-go.yaml
USER gitpod
ENV GO_VERSION=1.14.2 \
    GOPATH=$HOME/go-packages \
    GOROOT=$HOME/go
ENV PATH=$GOROOT/bin:$GOPATH/bin:$PATH
RUN curl -fsSL https://storage.googleapis.com/golang/go$GO_VERSION.linux-amd64.tar.gz | tar xzs
# user Go packages
ENV GOPATH=/workspace/go \
    PATH=/workspace/go/bin:$PATH

### Node.js ###
LABEL dazzle/layer=lang-node
LABEL dazzle/test=tests/lang-node.yaml
USER gitpod
ENV NODE_VERSION=12.16.3
RUN curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | PROFILE=/dev/null bash \
    && bash -c ". .nvm/nvm.sh \
        && nvm install $NODE_VERSION \
        && nvm alias default $NODE_VERSION \
        && npm install -g npm typescript yarn @appthreat/cdxgen" \
    && echo ". ~/.nvm/nvm-lazy.sh"  >> /home/gitpod/.bashrc.d/50-node
# above, we are adding the lazy nvm init to .bashrc, because one is executed on interactive shells, the other for non-interactive shells (e.g. plugin-host)
COPY --chown=gitpod:gitpod nvm-lazy.sh /home/gitpod/.nvm/nvm-lazy.sh
ENV PATH=$PATH:/home/gitpod/.nvm/versions/node/v${NODE_VERSION}/bin

### Python ###
LABEL dazzle/layer=lang-python
LABEL dazzle/test=tests/lang-python.yaml
USER gitpod
ENV PATH=$PATH:/home/gitpod/.local/bin
RUN python3 -m pip install --upgrade pip \
    && python3 -m pip install --upgrade \
        setuptools wheel virtualenv pipenv pylint rope flake8 \
        ansible-lint cfn-lint yamllint nodejsscan appthreat-depscan \
        mypy autopep8 pep8 pylama pydocstyle bandit notebook \
        twine \
    && mv /home/gitpod/.local/bin/scan /home/gitpod/.local/bin/depscan \
    && sudo rm -rf /tmp/*
# Gitpod will automatically add user site under `/workspace` to persist your packages.
# ENV PYTHONUSERBASE=/workspace/.pip-modules \
#    PIP_USER=yes

### Ruby ###
LABEL dazzle/layer=lang-ruby
LABEL dazzle/test=tests/lang-ruby.yaml
USER gitpod
RUN curl -sSL https://rvm.io/mpapis.asc | gpg --import - \
    && curl -sSL https://rvm.io/pkuczynski.asc | gpg --import - \
    && curl -fsSL https://get.rvm.io | bash -s stable \
    && bash -lc " \
        rvm requirements \
        && rvm install 2.6 \
        && rvm use 2.6 --default \
        && rvm rubygems current \
        && gem install bundler --no-document \
        && gem install solargraph --no-document \
        && gem install cfn-nag puppet-lint cyclonedx-ruby --no-document" \
    && echo '[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*' >> /home/gitpod/.bashrc.d/70-ruby
ENV GEM_HOME=/workspace/.rvm

### Prologue (built across all layers) ###
LABEL dazzle/layer=dazzle-prologue
LABEL dazzle/test=tests/prologue.yaml
USER root
RUN curl -o /usr/bin/dazzle-util -L https://github.com/csweichel/dazzle/releases/download/v0.0.3/dazzle-util_0.0.3_Linux_x86_64 \
    && chmod +x /usr/bin/dazzle-util
# merge dpkg status files
RUN cp /var/lib/dpkg/status /tmp/dpkg-status \
    && for i in $(ls /var/lib/apt/dazzle-marks/*.status); do /usr/bin/dazzle-util debian dpkg-status-merge /tmp/dpkg-status $i > /tmp/dpkg-status; done \
    && cp -f /var/lib/dpkg/status /var/lib/dpkg/status-old \
    && cp -f /tmp/dpkg-status /var/lib/dpkg/status \
    && mkdir -p /usr/local/src && chown -R gitpod:gitpod /usr/local/src
# copy tests to enable the self-test of this image
COPY tests /var/lib/dazzle/tests
COPY scan-install.sh /tmp
USER gitpod
ENV PATH=$PATH:/home/gitpod/.cargo/bin:
RUN curl -LO "https://github.com/ShiftLeftSecurity/sast-scan/archive/master.zip" \
    && unzip -q master.zip -d /usr/local/src \
    && pip install -r /usr/local/src/sast-scan-master/requirements.txt \
    && chmod +x /usr/local/src/sast-scan-master/scan \
    && rm master.zip
USER root
RUN chmod +x /tmp/scan-install.sh && bash /tmp/scan-install.sh \
    && curl -L https://sh.rustup.rs > rust-installer.sh \
    && chmod +x rust-installer.sh \
    && bash rust-installer.sh -y \
    && rm rust-installer.sh \
    && cargo install cargo-audit \
    && rm /tmp/scan-install.sh && ln -s /usr/local/src/sast-scan-master/scan /usr/local/bin/scan \
    && echo "\nexport PYTHONPATH=$PYTHONPATH:/home/gitpod/.local/lib/python3.8/site-packages:\nexport PATH=${PATH}:/usr/local/src/sast-scan-master:/opt/sl-cli:/usr/local/bin:/home/gitpod/.cargo/bin:\nexport DEPSCAN_CMD=\"/home/gitpod/.local/bin/depscan\"\n" >> /home/gitpod/.bashrc \
    && echo "export PMD_CMD=\"/opt/pmd-bin/bin/run.sh pmd\"\n" >> /home/gitpod/.bashrc \
    && echo "export CREDSCAN_CONFIG=\"/usr/local/src/sast-scan-master/credscan-config.toml\"\n" >> /home/gitpod/.bashrc \
    && echo "export SPOTBUGS_HOME=/opt/spotbugs" >> /home/gitpod/.bashrc

FROM builder

ENV SHIFTLEFT_HOME=/opt/sl-cli \
    APP_SRC_DIR=/usr/local/src/sast-scan-master \
    DEPSCAN_CMD="/home/gitpod/.local/bin/depscan" \
    PMD_CMD="/opt/pmd-bin/bin/run.sh pmd" \
    PMD_JAVA_OPTS="" \
    SPOTBUGS_HOME=/opt/spotbugs \
    PYTHONUNBUFFERED=1 \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    SHIFTLEFT_HOME=/opt/sl-cli \
    GO111MODULE=auto \
    GOARCH=amd64 \
    GOOS=linux \
    CREDSCAN_CONFIG="/usr/local/src/sast-scan-master/credscan-config.toml" \
    PYTHONPATH=$PYTHONPATH:/home/gitpod/.local/lib/python3.8/site-packages: \
    PATH=${PATH}:/usr/local/src/sast-scan-master:/opt/sl-cli:/usr/local/bin:/home/gitpod/.cargo/bin:

USER gitpod
