set -e

export INSTALLZSH="false"
export INSTALLOHMYZSH="false"
export INSTALLOHMYZSHCONFIG="false"

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

change_debian_source() {
    cat <<'EOF' >/etc/apt/sources.list.d/debian.sources
Types: deb
URIs: http://mirrors.cernet.edu.cn/debian
Suites: bookworm bookworm-updates bookworm-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
# Types: deb-src
# URIs: https://mirrors.cernet.edu.cn/debian
# Suites: bookworm bookworm-updates bookworm-backports
# Components: main contrib non-free non-free-firmware
# Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

# 以下安全更新软件源包含了官方源与镜像站配置，如有需要可自行修改注释切换
# Types: deb
# URIs: https://mirrors.cernet.edu.cn/debian-security
# Suites: bookworm-security
# Components: main contrib non-free non-free-firmware
# Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

# # Types: deb-src
# # URIs: https://mirrors.cernet.edu.cn/debian-security
# # Suites: bookworm-security
# # Components: main contrib non-free non-free-firmware
# # Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://security.debian.org/debian-security
Suites: bookworm-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

# Types: deb-src
# URIs: http://security.debian.org/debian-security
# Suites: bookworm-security
# Components: main contrib non-free non-free-firmware
# Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
}

change_ubuntu_source() {
    cat <<'EOF' >/etc/apt/sources.list.d/ubuntu.sources
Types: deb
URIs: http://mirror.nju.edu.cn/ubuntu
Suites: noble noble-updates noble-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
# Types: deb-src
# URIs: https://mirror.nju.edu.cn/ubuntu
# Suites: noble noble-updates noble-backports
# Components: main restricted universe multiverse
# Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# 以下安全更新软件源包含了官方源与镜像站配置，如有需要可自行修改注释切换
# Types: deb
# URIs: https://mirror.nju.edu.cn/ubuntu
# Suites: noble-security
# Components: main restricted universe multiverse
# Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# # Types: deb-src
# # URIs: https://mirror.nju.edu.cn/ubuntu
# # Suites: noble-security
# # Components: main restricted universe multiverse
# # Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://security.ubuntu.com/ubuntu/
Suites: noble-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# Types: deb-src
# URIs: http://security.ubuntu.com/ubuntu/
# Suites: noble-security
# Components: main restricted universe multiverse
# Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# 预发布软件源，不建议启用
# Types: deb
# URIs: https://mirror.nju.edu.cn/ubuntu
# Suites: noble-proposed
# Components: main restricted universe multiverse
# Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# # Types: deb-src
# # URIs: https://mirror.nju.edu.cn/ubuntu
# # Suites: noble-proposed
# # Components: main restricted universe multiverse
# # Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
}

change_source_https() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "Error: File '$file' does not exist or is not a regular file."
        return 1
    fi
    sed -i 's/URIs: http/URIs: https/g' "$file"
    if [[ $? -eq 0 ]]; then
        echo "Successfully replaced NJU mirror URL in '$file'."
    else
        echo "Failed to replace NJU mirror URL in '$file'."
    fi
}

install_aosp_packages() {
    local aosp_packages="git-core \
        flex \
        bison \
        build-essential \
        zlib1g-dev \
        gcc-multilib \
        g++-multilib \
        libc6-dev-i386 \
        x11proto-core-dev \
        libx11-dev \
        lib32z1-dev \
        libgl1-mesa-dev \
        libxml2-utils \
        xsltproc \
        fontconfig \
        lib32ncurses-dev \
        libncurses6 \
        python-is-python3"
    apt-get update -y
    apt-get -y install --no-install-recommends ${aosp_packages}
    # Clean up
    apt-get -y clean
    rm -rf /var/lib/apt/lists/*
}

add_repo() {
    echo "Downloading repo"
    local user_home="/home/${USERNAME}"
    local bin_dir="${user_home}/.local/bin"
    if [ ! -d "$bin_dir" ]; then
        mkdir -p "$bin_dir"
        echo "Created bin directory at $bin_dir"
    else
        echo "Existing $bin_dir"
    fi
    local user_rc_file
    if [ "${INSTALL_OH_MY_ZSH}" = "true" ]; then
        user_rc_file="${user_home}/.zshrc"
    else
        user_rc_file="${user_home}/.bashrc"
    fi
    local tmp_repo=$(mktemp /tmp/repo.XXXXXXXXX)
    curl -o ${tmp_repo} https://storage.googleapis.com/git-repo-downloads/repo
    gpg2 --recv-keys 8BB9AD793E8E6153AF0F9A4416530D5E920F5C65
    curl -s https://storage.googleapis.com/git-repo-downloads/repo.asc | gpg2 --verify - ${tmp_repo} && install -m 755 ${tmp_repo} ${bin_dir}/repo

    if echo "$PATH" | grep -q "$bin_dir"; then
        echo "Directory '$bin_dir' already exists in your PATH."
        exit 0
    fi
    echo "export PATH=\$PATH:${bin_dir}" >>${user_rc_file}
    . ${user_rc_file}
    echo "DONE!!!!"
}

. /etc/os-release
if [ "${ID}" = "debian" ]; then
    change_debian_source
else
    change_ubuntu_source
fi

/bin/bash "$(dirname $0)/main.sh" "$@"

if [ "$ID" = "debian" ]; then
    change_source_https /etc/apt/sources.list.d/debian.sources
else
    change_source_https /etc/apt/sources.list.d/ubuntu.sources
fi

install_aosp_packages
add_repo

exit $?
