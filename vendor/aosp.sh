set -e

export INSTALLZSH="false"
export INSTALLOHMYZSH="false"
export INSTALLOHMYZSHCONFIG="false"

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

change_source() {
    cat <<'EOF' >/etc/apt/sources.list
# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb http://mirror.nju.edu.cn/ubuntu/ focal main restricted universe multiverse
# deb-src http://mirror.nju.edu.cn/ubuntu/ focal main restricted universe multiverse
deb http://mirror.nju.edu.cn/ubuntu/ focal-updates main restricted universe multiverse
# deb-src http://mirror.nju.edu.cn/ubuntu/ focal-updates main restricted universe multiverse
deb http://mirror.nju.edu.cn/ubuntu/ focal-backports main restricted universe multiverse
# deb-src http://mirror.nju.edu.cn/ubuntu/ focal-backports main restricted universe multiverse

# 以下安全更新软件源包含了官方源与镜像站配置，如有需要可自行修改注释切换
deb http://mirror.nju.edu.cn/ubuntu/ focal-security main restricted universe multiverse
# deb-src http://mirror.nju.edu.cn/ubuntu/ focal-security main restricted universe multiverse

# deb http://security.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse
# # deb-src http://security.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse

# 预发布软件源，不建议启用
# deb http://mirror.nju.edu.cn/ubuntu/ focal-proposed main restricted universe multiverse
# # deb-src http://mirror.nju.edu.cn/ubuntu/ focal-proposed main restricted universe multiverse
EOF
}

change_https() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "Error: File '$file' does not exist or is not a regular file."
        return 1
    fi
    sed -i 's/http/https/g' "$file"
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
        lib32ncurses5-dev \
        libncurses5 \
        python-is-python2 \
        python-crypto"
    apt-get update -y
    apt-get -y install --no-install-recommends ${aosp_packages}
    apt-get -y clean
    rm -rf /var/lib/apt/lists/*
}

change_source
/bin/bash "$(dirname $0)/main.sh" "$@"
change_https /etc/apt/sources.list
install_aosp_packages
exit $?
