FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

# Install base packages + Node.js (required by AI tools scripts)
RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends \
        curl \
        git \
        vim \
        zsh \
        sudo \
        ca-certificates \
        locales \
        shellcheck \
        nodejs \
        npm \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Create non-root test user with passwordless sudo
RUN useradd -m -s /bin/zsh testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/testuser && \
    chmod 0440 /etc/sudoers.d/testuser

USER testuser
WORKDIR /home/testuser

# Install chezmoi
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
ENV PATH="/home/testuser/.local/bin:${PATH}"

# Pre-create chezmoi config for non-interactive mode
RUN mkdir -p ~/.config/chezmoi && \
    printf '[data]\n    name = "Test User"\n    email = "test@example.com"\n' > ~/.config/chezmoi/chezmoi.toml

# Copy source directory
COPY --chown=testuser:testuser home/ /home/testuser/.local/share/chezmoi/

# Test script
COPY --chown=testuser:testuser tests/linux.sh /home/testuser/linux.sh
RUN chmod +x /home/testuser/linux.sh

CMD ["/home/testuser/linux.sh"]
