FROM centos:7

RUN yum -y update
#RUN yum -y groupinstall "GNOME Desktop"
RUN yum -y install \
    #1:dbus-libs \
    #1:openssl-libs \
    #1:qt-x11 \
    #2:libpng \
    #at-spi2-atk \
    #at-spi2-core \
    #atk \
    #bzip2-libs \
    #cairo \
    #cairo-gobject \
    #dbus-libs \
    #elfutils-libelf \
    #elfutils-libs \
    #expat \
    #fontconfig \
    #freetype \
    #fribidi \
    #gdk-pixbuf2 \
    #glib2 \
    #glibc \
    #graphite2 \
    gtk3 \
    #harfbuzz \
    #keyutils-libs \
    #krb5-libs \
    #libX11 \
    #libXau \
    #libXcomposite \
    #libXcursor \
    #libXdamage \
    #libXext \
    #libXfixes \
    #libXi \
    #libXinerama \
    #libXrandr \
    #libXrender \
    #libattr \
    #libblkid \
    #libcap \
    #libcom_err \
    #libepoxy \
    #libffi \
    #libgcc \
    #libgcrypt \
    #libgpg-error \
    libicu \
    #libmount \
    #libpng \
    #libselinux \
    #libthai \
    #libuuid \
    #libwayland-client \
    #libwayland-cursor \
    #libwayland-egl \
    #libxcb \
    #libxkbcommon \
    libxkbcommon-x11 \
    #lz4 \
    #ncurses-libs \
    #nss-softokn-freebl \
    #openssl-libs \
    #pango \
    #pcre \
    pcre2-utf16 \
    #pixman \
    python-cffi \
    #python-libs \
    #qt5-qtbase \
    #qt5-qtbase-gui \
    #qt5-qtdeclarative \
    #qt5-qtsvg \
    #qt5-qtwayland \
    #qt5-qtwebsockets \
    #readline \
    #sqlite \
    #systemd-libs \
    xcb-util \
    xcb-util-image \
    xcb-util-keysyms \
    xcb-util-renderutil \
    xcb-util-wm
    #xz-libs \
    #zlib

COPY scripts/provision_devtools.sh /
RUN /provision_devtools.sh && rm /provision_devtools.sh
