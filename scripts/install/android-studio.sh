#!/bin/sh

# prerequisites
dnf install zlib.i686 ncurses-libs.i686 bzip2-libs.i686 java-1.8.0-openjdk-javadoc java-1.8.0-openjdk-devel

# download binary
cd /opt
URL=https://dl.google.com/dl/android/studio/ide-zips/3.4.0.18
wget ${URL}/android-studio-ide-183.5452501-linux.tar.gz
tar -xzf android-studio-ide-183.5452501-linux.tar.gz
rm -f android-studio-ide-183.5452501-linux.tar.gz

# Create a desktop entry
cat <<EOF | sudo tee /usr/local/share/applications/android-studio.desktop
[Desktop Entry]
Type=Application
Name=Android Studio
Icon=/opt/android-studio/bin/studio.png
Exec=env _JAVA_OPTIONS=-Djava.io.tmpdir=/var/tmp /opt/android-studio/bin/studio.sh
Terminal=false
Categories=Development;IDE;
EOF