FROM ubuntu:26.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends \
        bat \
        ca-certificates \
        curl \
        git \
        gnupg \
        jq \
        locales \
        make \
        openssh-client \
        shellcheck \
        sudo \
        vim \
        zoxide \
        zsh \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/testuser && \
    chmod 0440 /etc/sudoers.d/testuser

USER testuser
WORKDIR /home/testuser

RUN curl -fsLS https://get.chezmoi.io -o /tmp/install-chezmoi.sh && \
    sh /tmp/install-chezmoi.sh -b "$HOME/.local/bin" && \
    rm -f /tmp/install-chezmoi.sh
ENV PATH="/home/testuser/.local/bin:${PATH}"

RUN mkdir -p "$HOME/.config/chezmoi" && \
    printf '%s\n' \
        '[data]' \
        '    name = "TestUser"' \
        '    email = "test@example.com"' \
        '    deviceName = "test-device"' \
        > "$HOME/.config/chezmoi/chezmoi.toml"

COPY --chown=testuser:testuser home/ /home/testuser/.local/share/chezmoi/
COPY --chown=testuser:testuser tests/ /home/testuser/tests/

RUN test ! -e /home/testuser/tests/fixtures/.env.test-fixture

CMD ["bash", "/home/testuser/tests/run.sh", "linux"]
