FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Deps Android + Flutter
RUN apt-get update && apt-get install -y --no-install-recommends \
  curl unzip xz-utils zip libglu1-mesa openjdk-17-jdk \
  && rm -rf /var/lib/apt/lists/*

# Android SDK (cmdline tools only, licenses acceptees via flutter doctor)
ENV ANDROID_SDK_ROOT=/home/vscode/Android/Sdk
ENV PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools \
  && curl -o /tmp/cmdtools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
  && unzip /tmp/cmdtools.zip -d $ANDROID_SDK_ROOT/cmdline-tools \
  && mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest \
  && rm /tmp/cmdtools.zip \
  && chown -R vscode:vscode /home/vscode/Android || true
