# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.205.2/containers/ubuntu/.devcontainer/base.Dockerfile

# [Choice] Ubuntu version (use hirsuite or bionic on local arm64/Apple Silicon): hirsute, focal, bionic
ARG VARIANT="hirsute"
FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}

# [Optional] Uncomment this section to install additional OS packages.
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends awscli


# sudo apt-get update
# sudo apt-get install ca-certificates curl apt-transport-https lsb-release gnupg

# curl -sL https://packages.microsoft.com/keys/microsoft.asc |
#     gpg --dearmor |
#     sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

# AZ_REPO=$(lsb_release -cs)
# echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" |
#     sudo tee /etc/apt/sources.list.d/azure-cli.list

# sudo apt-get update
# sudo apt-get install azure-cli