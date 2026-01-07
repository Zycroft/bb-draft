# Flutter Development Environment
# Use Ubuntu as base for better compatibility
FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    # Chrome dependencies for web development
    wget \
    gnupg2 \
    apt-transport-https \
    ca-certificates \
    # Clean up
    && rm -rf /var/lib/apt/lists/*

# Install Google Chrome for web testing
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for development
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && rm -rf /var/lib/apt/lists/*

# Switch to non-root user
USER $USERNAME
WORKDIR /home/$USERNAME

# Set up Flutter SDK
ENV FLUTTER_VERSION=3.38.5
ENV FLUTTER_HOME=/home/$USERNAME/flutter
ENV PATH="$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH"

# Download and install Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_HOME \
    && cd $FLUTTER_HOME \
    && git checkout $FLUTTER_VERSION

# Pre-download Flutter artifacts and enable web
RUN flutter precache --web \
    && flutter config --enable-web \
    && flutter doctor

# Set Chrome as the web browser for Flutter
ENV CHROME_EXECUTABLE=/usr/bin/google-chrome

# Create workspace directory
WORKDIR /workspace

# Expose port for Flutter web development server
EXPOSE 8080 5000

# Default command
CMD ["bash"]
