#!/bin/bash
#jlst 2015

# When building a chain of static dependencies, force
# PKG_CONFIG_PATH="${BUILDDIR}/lib/pkgconfig" for every package, unless
# it'ѕ a very basic lib with trivial dependencies.  Check the dependency
# list in packages.ubuntu.com or Linux From Scratch, and with ldd, and
# with grep dependency_libs= *.la.

scriptdir=${0%/*}
scriptfile=${0##*/}

case $scriptdir in
	 .*)  DIR=${PWD}       ;;
	 /*)  DIR=${scriptdir} ;;
	  *)  DIR=${scriptdir} ;;
esac

cd "$DIR"

ROOTDIR="$DIR"
BUILDDIR="$DIR/build"
SOURCEDIR="$DIR/sources"

mkdir -p "$BUILDDIR"
mkdir -p "$BUILDDIR/bin"
mkdir -p "$BUILDDIR/lib"
mkdir -p "$BUILDDIR/include"
mkdir -p "$SOURCEDIR"

# build libexpat.a first. Fatdog64 note: OS includes and links libexpat.so, which is OK.
if [ ! -f "$BUILDDIR/lib/libexpat.a" ] ; then #http://sourceforge.net/projects/expat/files/expat/2.1.0/
	cd ${SOURCEDIR}
	wget http://sourceforge.net/projects/expat/files/expat/2.1.0/expat-2.1.0.tar.gz
	tar xzvf expat-2.1.0.tar.gz ; cd expat-2.1.0 ; ./configure --prefix="$BUILDDIR" --disable-shared --enable-static 
	make && make install
fi

# Fatdog64: build libjpeg.a first. Fatdog64 note: OS includes and links libjpeg.8.1.so, which is OK.
# When linking mpv the linker links libv4lconvert.so which depends on libjpeg.*.so.
if [ ! -f "$BUILDDIR/lib/libjpeg.a" ] ; then
	cd ${SOURCEDIR}
	wget http://ijg.org/files/jpegsrc.v9a.tar.gz
	tar zxf jpegsrc.v9a.tar.gz ; cd jpeg-9a
	PKG_CONFIG_PATH="${BUILDDIR}/lib/pkgconfig" ./configure --prefix="$BUILDDIR" --disable-shared --enable-static && make && make install
fi

#Fatdog64: suspend conflicting dynamic libs .so; DO THIS IN A SANDBOX!
# NOT USED
for i in ; do
  for p in /lib64 /usr/lib64 /usr/local/lib64; do
    if ls "${p}/lib${i}."* >/dev/null 2>&1; then
      t="${p}/lib${i}_SUSPEND"
      mkdir -p "${t}" && mv "${p}/lib${i}."* "${t}/"
    fi
  done
done

if [ ! -f "$BUILDDIR/bin/yasm" ] ; then
	cd ${SOURCEDIR}
	wget -c http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz
	tar xzvf yasm-1.3.0.tar.gz
	cd yasm-1.3.0
	./configure --prefix="$BUILDDIR" --bindir="$BUILDDIR/bin" && make && make install
fi

if [ ! -f "$BUILDDIR/lib/libx264.a" ] ; then
	cd ${SOURCEDIR}
	wget http://download.videolan.org/pub/x264/snapshots/last_x264.tar.bz2
	tar xjvf last_x264.tar.bz2
	cd x264-snapshot*
	PATH="$BUILDDIR/bin:$PATH" ./configure --prefix="$BUILDDIR" --bindir="$BUILDDIR/bin" --enable-static
	PATH="$BUILDDIR/bin:$PATH" make && make install
fi

if [ ! -f "$BUILDDIR/lib/libx265.a" ] ; then
	cd ${SOURCEDIR}
	hg clone https://bitbucket.org/multicoreware/x265
	cd ${SOURCEDIR}/x265/build/linux
	PATH="$BUILDDIR/bin:$PATH" cmake -DCMAKE_INSTALL_PREFIX="$BUILDDIR" -DENABLE_SHARED:bool=off ../../source
	make && make install
fi

if [ ! -f "$BUILDDIR/lib/libfdk-aac.a" ] ; then
	cd ${SOURCEDIR}
	wget -c -O fdk-aac.tar.gz https://github.com/mstorsjo/fdk-aac/tarball/master
	tar xzvf fdk-aac.tar.gz ; cd mstorsjo-fdk-aac*
	autoreconf -fiv ; ./configure --prefix="$BUILDDIR" --disable-shared && make && make install
fi

if [ ! -f "$BUILDDIR/lib/libmp3lame.a" ] ; then
	cd ${SOURCEDIR}
	curl -L -o lame-3.99.5.tar.gz http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz
	tar xzvf lame-3.99.5.tar.gz
	cd lame-3.99.5
	./configure --prefix="$BUILDDIR" --enable-nasm --disable-shared && make && make install
fi

if [ ! -f "$BUILDDIR/lib/libopus.a" ] ; then
	cd ${SOURCEDIR}
	wget http://downloads.xiph.org/releases/opus/opus-1.1.tar.gz
	tar xzvf opus-1.1.tar.gz ; cd opus-1.1
	./configure --prefix="$BUILDDIR" --disable-shared && make && make install
fi

if [ ! -f "$BUILDDIR/lib/libvpx.a" ] ; then
	cd ${SOURCEDIR}
	wget http://storage.googleapis.com/downloads.webmproject.org/releases/webm/libvpx-1.4.0.tar.bz2
	tar xjvf libvpx-1.4.0.tar.bz2
	cd libvpx-1.4.0
	PATH="$BUILDDIR/bin:$PATH" ./configure --prefix="$BUILDDIR" --disable-examples --disable-unit-tests
	PATH="$BUILDDIR/bin:$PATH" make && make install
fi

if [ ! -f "$BUILDDIR/lib/libass.a" ] ; then
	cd ${SOURCEDIR}
	wget https://github.com/libass/libass/releases/download/0.12.3/libass-0.12.3.tar.gz
	tar -zxf libass-0.12.3.tar.gz
	cd libass-0.12.3
	PATH="$BUILDDIR/bin:$PATH" ./configure --prefix="$BUILDDIR" --disable-shared --enable-static
	PATH="$BUILDDIR/bin:$PATH" make && make install
fi

if [ ! -f "$BUILDDIR/lib/libvorbis.a" ] ; then
	cd ${SOURCEDIR}
	wget http://downloads.xiph.org/releases/ogg/libogg-1.3.2.tar.gz
	tar -zxf libogg-1.3.2.tar.gz
	cd libogg-1.3.2
	PATH="$BUILDDIR/bin:$PATH" ./configure --prefix="$BUILDDIR" --disable-shared --enable-static
	PATH="$BUILDDIR/bin:$PATH" make && make install
	cd ${SOURCEDIR}
	wget http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.5.tar.gz
	tar -zxf libvorbis-1.3.5.tar.gz
	cd libvorbis-1.3.5
  PKG_CONFIG_PATH="${BUILDDIR}/lib/pkgconfig" PATH="$BUILDDIR/bin:$PATH" ./configure --prefix="$BUILDDIR" --disable-shared --enable-static
	PATH="$BUILDDIR/bin:$PATH" make && make install
fi

if [ ! -f "$BUILDDIR/lib/libtheora.a" ] ; then
	cd ${SOURCEDIR}
	wget http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.bz2
	tar -jxf libtheora-1.1.1.tar.bz2
	cd libtheora-1.1.1
	PATH="$BUILDDIR/bin:$PATH" ./configure --prefix="$BUILDDIR" --disable-shared --enable-static --disable-examples
	PATH="$BUILDDIR/bin:$PATH" make && make install
fi

if [ ! -f "$BUILDDIR/lib/libxvidcore.a" ] ; then
	cd ${SOURCEDIR}
	wget http://downloads.xvid.org/downloads/xvidcore-1.3.4.tar.gz
	tar -zxf xvidcore-1.3.4.tar.gz
	cd xvidcore/build/generic
	PATH="$BUILDDIR/bin:$PATH" ./configure --prefix="$BUILDDIR" --disable-shared --enable-static
	PATH="$BUILDDIR/bin:$PATH" make && make install ; make clean
	rm -v $BUILDDIR/lib/libxvidcore.so*	
fi

if [ ! -f "$BUILDDIR/lib/libsoxr.a" ] ; then
	cd ${SOURCEDIR}
	curl -L -o soxr-0.1.1-Source.tar.xz http://sourceforge.net/projects/soxr/files/soxr-0.1.1-Source.tar.xz/download
	tar -Jxf soxr-0.1.1-Source.tar.xz
	cd soxr-0.1.1-Source
	PATH="$BUILDDIR/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$BUILDDIR" -DBUILD_SHARED_LIBS="OFF" .
	PATH="$BUILDDIR/bin:$PATH" make && make install
fi

if [ ! -f "$BUILDDIR/lib/libFLAC.a" ] ; then
	cd ${SOURCEDIR}
	wget http://downloads.xiph.org/releases/flac/flac-1.3.1.tar.xz
	tar -Jxf flac-1.3.1.tar.xz
	cd flac-1.3.1
	PATH="$BUILDDIR/bin:$PATH" ./configure --prefix="$BUILDDIR" --disable-shared --enable-static --with-ogg="${BUILDDIR}/lib/libogg.a"
	PATH="$BUILDDIR/bin:$PATH" make && make install
fi

if [ ! -f "$BUILDDIR/lib/libspeex.a" ] ; then
	cd ${SOURCEDIR}
	wget http://downloads.xiph.org/releases/speex/speex-1.2rc1.tar.gz
	tar -zxf speex-1.2rc1.tar.gz
	cd speex-1.2rc1
	PATH="$BUILDDIR/bin:$PATH" ./configure --prefix="$BUILDDIR" --disable-shared --enable-static
	PATH="$BUILDDIR/bin:$PATH" make && make install
fi

if [ ! -f "$BUILDDIR/lib/libopenjp2.a" ] ; then
	cd ${SOURCEDIR}
	wget -c -O openjpeg.tar.gz https://github.com/uclouvain/openjpeg/tarball/master
	tar xzvf openjpeg.tar.gz
	cd uclouvain-openjpeg*
	PATH="$BUILDDIR/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$BUILDDIR" -DBUILD_SHARED_LIBS="OFF" .
	PATH="$BUILDDIR/bin:$PATH" make && make install
fi

if [ ! -f "$BUILDDIR/lib/libopencore-amrnb.a" ] ; then
	cd ${SOURCEDIR}
	curl -L -o opencore-amr-0.1.3.tar.gz http://sourceforge.net/projects/opencore-amr/files/opencore-amr/opencore-amr-0.1.3.tar.gz/download
	tar xzvf opencore-amr-0.1.3.tar.gz ; cd opencore-amr-0.1.3
	PATH="$BUILDDIR/bin:$PATH" ./configure --prefix="$BUILDDIR" --disable-shared --enable-static
	PATH="$BUILDDIR/bin:$PATH" make && make install
fi

if [ ! -f "$BUILDDIR/lib/libwavpack.a" ] ; then
	cd ${SOURCEDIR}
	wget http://www.wavpack.com/wavpack-4.75.0.tar.bz2
	tar xjvf wavpack-4.75.0.tar.bz2 ; cd wavpack-4.75.0
	PATH="$BUILDDIR/bin:$PATH" ./configure --prefix="$BUILDDIR" --disable-shared --enable-static && make && make install 
fi

if [ ! -f "$BUILDDIR/lib/libvo-aacenc.a" ] ; then
	cd ${SOURCEDIR}
	wget http://sourceforge.net/projects/opencore-amr/files/vo-aacenc/vo-aacenc-0.1.3.tar.gz
	tar xzvf vo-aacenc-0.1.3.tar.gz
	cd vo-aacenc-0.1.3
	PATH="$BUILDDIR/bin:$PATH" ./configure --prefix="$BUILDDIR" --disable-shared --enable-static && make && make install
fi

#########################################################################################

## linking problems in precise puppy 5.7.1
if [ ! -f "$BUILDDIR/lib/libcdio.a" ] ; then
	### http://www.linuxfromscratch.org/blfs/view/svn/multimedia/libcdio.html
	cd ${SOURCEDIR}
	wget http://prdownloads.sourceforge.net/libcddb/libcddb-1.3.2.tar.bz2
	tar xjvf libcddb-1.3.2.tar.bz2 
	cd libcddb-1.3.2
	PKG_CONFIG_PATH="${BUILDDIR}/lib/pkgconfig" ./configure --prefix="$BUILDDIR" --disable-shared --enable-static --without-cdio 
	sed -i 's|.*#undef HAVE_ICONV.*|#define HAVE_ICONV 1|' config.h
	make && make install
	cd ${SOURCEDIR}
	wget http://ftp.gnu.org/gnu/libcdio/libcdio-0.93.tar.bz2
	tar xjvf libcdio-0.93.tar.bz2 ; cd libcdio-0.93
	PKG_CONFIG_PATH="${BUILDDIR}/lib/pkgconfig" ./configure --prefix="$BUILDDIR" --disable-shared --enable-static --without-cd-drive
	sed -i 's|.*#undef HAVE_ICONV.*|#define HAVE_ICONV 1|' config.h
	make && make install
	cd ${SOURCEDIR}
	wget http://ftp.gnu.org/gnu/libcdio/libcdio-paranoia-10.2+0.93+1.tar.bz2
	tar xjvf libcdio-paranoia-10.2+0.93+1.tar.bz2 ; cd libcdio-paranoia-10.2+0.93+1
	PKG_CONFIG_PATH="${BUILDDIR}/lib/pkgconfig" ./configure --prefix="$BUILDDIR" --disable-shared --enable-static 
	sed -i 's|.*#undef HAVE_ICONV.*|#define HAVE_ICONV 1|' config.h
	make && make install
fi

if [ ! -f "$BUILDDIR/lib/libdvdnav.a" ] ; then
	cd ${SOURCEDIR}
	wget http://download.videolan.org/pub/videolan/libdvdcss/1.3.99/libdvdcss-1.3.99.tar.bz2
	tar xjf libdvdcss-1.3.99.tar.bz2 ; cd libdvdcss-1.3.99 
	PKG_CONFIG_PATH="${BUILDDIR}/lib/pkgconfig" ./configure --prefix="$BUILDDIR" --disable-shared --enable-static && make && make install
	cd ${SOURCEDIR}
	wget http://download.videolan.org/pub/videolan/libdvdread/5.0.3/libdvdread-5.0.3.tar.bz2
	tar xjf libdvdread-5.0.3.tar.bz2 ; cd libdvdread-5.0.3
	PKG_CONFIG_PATH="${BUILDDIR}/lib/pkgconfig" ./configure --prefix="$BUILDDIR" --disable-shared --enable-static && make && make install
	cd ${SOURCEDIR}
	wget http://download.videolan.org/pub/videolan/libdvdnav/5.0.3/libdvdnav-5.0.3.tar.bz2
	tar xjf libdvdnav-5.0.3.tar.bz2 ; cd libdvdnav-5.0.3
	PKG_CONFIG_PATH="${BUILDDIR}/lib/pkgconfig" ./configure --prefix="$BUILDDIR" --disable-shared --enable-static && make && make install
fi

if [ ! -f "$BUILDDIR/lib/libbluray.a" ] ; then
	#cd ${SOURCEDIR}
	#wget ftp://xmlsoft.org/libxml2/libxml2-2.9.2.tar.gz
	#tar zxf libxml2-2.9.2.tar.gz ; cd libxml2-2.9.2
	#./configure --prefix="$BUILDDIR" --disable-shared --enable-static --without-python && make && make install
	cd ${SOURCEDIR}
	wget http://download.videolan.org/pub/videolan/libbluray/0.8.1/libbluray-0.8.1.tar.bz2
	tar xjf libbluray-0.8.1.tar.bz2 ; cd libbluray-0.8.1
	PKG_CONFIG_PATH="${BUILDDIR}/lib/pkgconfig"  ./configure --prefix="$BUILDDIR" --disable-shared --enable-static --disable-bdjava --enable-udf --without-libxml2
	make clean && make && make install
fi

if [ ! -f "$BUILDDIR/lib/libluajit-5.1.a" ] ; then
	cd ${SOURCEDIR}
	wget http://luajit.org/download/LuaJIT-2.0.3.tar.gz
	tar zxf LuaJIT-2.0.3.tar.gz ; cd LuaJIT-2.0.3
	sed -i "s| PREFIX=.*| PREFIX=${BUILDDIR}|" Makefile
	PKG_CONFIG_PATH="${BUILDDIR}/lib/pkgconfig" make && make install
	rm -v $BUILDDIR/lib/libluajit-5.1.so*
fi

if [ ! -f "$BUILDDIR/lib/libenca.a" ] ; then
	cd ${SOURCEDIR}
	wget http://dl.cihar.com/enca/enca-1.16.tar.gz
	tar zxf enca-1.16.tar.gz ; cd enca-1.16
	PKG_CONFIG_PATH="${BUILDDIR}/lib/pkgconfig" ./configure --prefix="$BUILDDIR" --disable-shared --enable-static && make && make install
fi

if [ ! -f "$BUILDDIR/lib/libfribidi.a" ] ; then
	cd ${SOURCEDIR}
	wget http://fribidi.org/download/fribidi-0.19.7.tar.bz2
	tar jxf fribidi-0.19.7.tar.bz2 ; cd fribidi-0.19.7
	./configure --prefix="$BUILDDIR" --disable-shared --enable-static && make && make install
fi

##linking problems
#	cd ${SOURCEDIR}
#	git clone -b master --depth 1 https://github.com/kaniini/libguess.git
#	cd libguess ; ./autogen.sh
#	PKG_CONFIG_PATH="${BUILDDIR}/lib/pkgconfig" ./configure --prefix="$BUILDDIR" --disable-shared --enable-static && make && make install

## linking problems
#if [ ! -f "$BUILDDIR/lib/libuchardet.a" ] ; then
#	cd ${SOURCEDIR}
#	git clone -b master --depth 1 https://github.com/BYVoid/uchardet ; cd uchardet 
#	PKG_CONFIG_PATH="${BUILDDIR}/lib/pkgconfig" cmake -DCMAKE_INSTALL_PREFIX="$BUILDDIR" . && make && make install
#	rm -v $BUILDDIR/lib/libuchardet.so*
#fi

#if [ ! -f "$BUILDDIR/lib/libbz2.a" ] ; then
#	cd ${SOURCEDIR}
#	wget http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz
#	tar zxf bzip2-1.0.6.tar.gz ; cd bzip2-1.0.6 
#	sed -i "s|^PREFIX=.*|PREFIX=${BUILDDIR}|" Makefile && make && make install
#fi
#if [ ! -f "$BUILDDIR/lib/liblzma.a" ] ; then
#	cd ${SOURCEDIR}
#	wget http://tukaani.org/xz/xz-5.2.1.tar.gz
#	tar zxf xz-5.2.1.tar.gz ; cd xz-5.2.1
#	PKG_CONFIG_PATH="${BUILDDIR}/lib/pkgconfig" ./configure --prefix="$BUILDDIR" --disable-shared --enable-static && make && make install
#fi

####################
#	cd ${SOURCEDIR}
#	wget http://www.openssl.org/source/openssl-1.0.2d.tar.gz
#	tar xzvf openssl-1.0.2d.tar.gz
#	cd openssl-1.0.2d
#	./config --prefix=/usr --openssldir=/etc/ssl --libdir=lib shared zlib-dynamic &&
#	PATH="$BUILDDIR/bin:$PATH" ./configure --prefix="$BUILDDIR" --disable-shared --enable-static
#	PATH="$BUILDDIR/bin:$PATH" make
#	make
#	make install
####################

#####################################################################################
# exit
#####################################################################################

#fix prefix for built packages (in case of path change)
[ -e  "${BUILDDIR}/lib/pkgconfig" ] &&
  sed -i "s|^prefix=.*|prefix=${BUILDDIR}|" "${BUILDDIR}/lib/pkgconfig/"*
if ls "${BUILDDIR}/lib/"*.la >/dev/null 2>&1; then
  sed -i "s|^libdir=.*|libdir=${BUILDDIR}/lib|" ${BUILDDIR}/lib/*.la
  sed -i "s|^prefix=.*|libdir=${BUILDDIR}/lib|" ${BUILDDIR}/lib/*.la #fix damaged lines, if any
fi

need_rebuild () { # $1-target-path
  [ ! -e "$1" ] && return 0
  local latest
  latest=$(ls -t "$1" "${BUILDDIR}/lib/"*.a 2>/dev/null | head -1)
  [ "$(basename "$1")" != "$(basename "${latest}")" ]
}

ffmpeg=0 #0:disable 1:configure&build 2:build
mpv=2 #0:disable 1:configure&build 2:build

if [ "$ffmpeg" -ne 0 ] && need_rebuild "$SOURCEDIR/ffmpeg/ffmpeg"; then
  rm -f "$SOURCEDIR/ffmpeg/ffmpeg"
	
	cd ${SOURCEDIR}
	
	if [ ! -d ffmpeg ] ; then
		git clone -b master --depth 1 git://source.ffmpeg.org/ffmpeg.git
		tar -zcf ffmpeg.tar.gz ffmpeg
	else
		echo '-------------------------------------------'
		echo "Remove [ $PWD/ffmpeg ] to redownload latest git"
		echo '-------------------------------------------'	
	fi

	cd ffmpeg
	[ $? -ne 0 ] && echo 'ERROR entering ffmpeg' && exit 1

	xbc='--disable-libxcb --disable-libxcb-shm --disable-libxcb-xfixes --disable-libxcb-shape'
	xlib='--disable-xlib --disable-x11grab'
	doc='--disable-doc --disable-manpages'
	staticlib='--disable-shared --enable-static'
	
	licenses='--enable-gpl --enable-version3 --enable-nonfree'
	
	basic='--enable-libass --enable-libfreetype'
	basicao='--enable-libfdk-aac --enable-libmp3lame --enable-libvpx --enable-libx264'
	extraaudio='--enable-libvorbis --enable-libspeex --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libwavpack --enable-libopus'
	extravideo='--enable-libtheora --enable-libx265 --enable-libxvid'
	
	preset=mpv #limitedffmpeg mpv minimallibav
	echo "preset: $preset"

	case "$preset" in
  limitedffmpeg)
		extra='--disable-ffserver --disable-ffplay --disable-sdl'
    ;;
  mpv)
		basicao=''
		extraaudio=''
		extravideo=''
		extra='--disable-ffserver --disable-ffprobe --disable-ffplay --disable-sdl'
		extra2='--enable-openssl --disable-encoders' #--disable-muxers
    ;;
  minimallibav)
		basicao=''
		extraaudio=''
		extravideo=''
		extra='--disable-ffserver --disable-ffprobe --disable-ffplay --disable-sdl'
		extra2='--disable-network --disable-encoders --disable-muxers --disable-bsfs --disable-filters' 
    ;;
  esac
	
	./configure --help >../../ffmpeg.help
	
	if [ -f config.h ] ; then
		echo '-----------------------------------------'
		echo "Remove [ $PWD/config.h ] to force reconfigure"
		echo '-----------------------------------------'
		ffconfig='echo'
	else
		ffredir='&>../../ffmpeg.configure'
	fi
	
	[ "$staticlib" ] && echo "--- Will build ffmpeg static libs" && echo

	#PATH="$BUILDDIR/bin:$PATH" LD_LIBRARY_PATH="${BUILDDIR}/lib:$LD_LIBRARY_PATH" PKG_CONFIG_PATH="${BUILDDIR}/lib/pkgconfig:$PKG_CONFIG_PATH" 	
  if [ ${ffmpeg} -lt 2 ]; then
	  PATH="$BUILDDIR/bin:$PATH" PKG_CONFIG_PATH="${BUILDDIR}/lib/pkgconfig" \
	  eval ${ffconfig} ./configure \
		  --prefix="$BUILDDIR" ${xbc} ${xlib} ${doc} \
		  --pkg-config-flags="--static" ${staticlib} \
		  --extra-cflags="-I${BUILDDIR}/include" \
		  --extra-ldflags="-L${BUILDDIR}/lib" \
		  --bindir="${BUILDDIR}/bin" \
		  ${licenses} ${basic} ${basicao} ${extraaudio} ${extravideo} ${extra} ${extra2} ${ffredir}
		[ $? -ne 0 ] && echo 'ERROR' && exit 1
  fi
	PATH="$BUILDDIR/bin:$PATH" make
	[ $? -ne 0 ] && PATH="$BUILDDIR/bin:$PATH" make
	make install

	mkdir "$DIR/output"
	[ -f "$SOURCEDIR/ffmpeg/ffmpeg" ] && cp "$SOURCEDIR/ffmpeg/ffmpeg" "$ROOTDIR/output"
	[ -f "$SOURCEDIR/ffmpeg/ffplay" ] && cp "$SOURCEDIR/ffmpeg/ffplay" "$ROOTDIR/output"
	[ -f "$SOURCEDIR/ffmpeg/ffprobe" ] && cp "$SOURCEDIR/ffmpeg/ffprobe" "$ROOTDIR/output"
	[ -f "$SOURCEDIR/ffmpeg/ffserver" ] && cp "$SOURCEDIR/ffmpeg/ffserver" "$ROOTDIR/output"

	#find "$SOURCEDIR/ffmpeg" -type f | grep -v "\.h$" | while read file ; do rm -rf $file ; done
	#find "$SOURCEDIR/ffmpeg" -maxdepth 1 -type d | grep -v "^${SOURCEDIR}/ffmpeg$" | grep -v lib | while read dir ; do rm -rfv $dir ; done
	#cp -rfv $SOURCEDIR/ffmpeg/* "${BUILDDIR}/include"
fi

spek=0
if [ ${spek} -eq 1 ] ; then
	cd ${SOURCEDIR}
	wget https://spek.googlecode.com/files/spek-0.8.2.tar.xz
	tar Jxf spek-0.8.2.tar.xz ; cd spek-0.8.2
	#if [ ! -d spek ] ; then
	#	git clone https://github.com/alexkay/spek
	#	cd spek ; git reset --hard 2c44de0e9ee3d34a516b5351cb801d0b6975a5f1 ; cd ..
	#fi
	cd spek
	spekdir=${ROOTDIR}/output-spek
	mkdir ${spekdir}
	#PKG_CONFIG_PATH="${BUILDDIR}/lib/pkgconfig" ./autogen.sh --prefix=${spekdir}
	PKG_CONFIG_PATH="${BUILDDIR}/lib/pkgconfig" ./configure --prefix=${spekdir}
	make clean && make && make install
	exit $?
fi

####################################################################################

PATCH1 () {
  # Patch wsscript* for static libs
  # ref. 10.3.3 of https://waf.io/book/#_library_interaction_use
  echo "patching waf script (PATCH1)" >&2
  awk -v stlibs="$(basename -a -s .a "${BUILDDIR}/lib/"*.a)" \
    -v builddir="${BUILDDIR}" -v q="'" '
  #match:<indent>use          = ctx.dependencies_use() + ['objects'],
  /use[ \t]*=[^[]+[[].objects.[]]/ {
    sub(/objects/, "PATCH1"q","q"&")
  }
  {print}
  ' wscript_build.py > /tmp/wscript_build.py &&
  mv -f /tmp/wscript_build.py wscript_build.py &&
  awk -v stlibs="'$(basename -a -s .a "${BUILDDIR}/lib/"*.a)'" \
    -v stlibdir="'${BUILDDIR}/lib'" -v q="'" '
  #match:<indent>if target:
  /if target:/ {
    indent=$0
    sub(/([^ \t]+).*$/, "",indent)
    gsub(/\n/, q","q, stlibs)
    gsub(q"lib",q,stlibs) # libogg.a => -logg
    printf "%sctx.env.STLIBPATH_PATCH1 = [%s]\n", indent,stlibdir
    printf "%sctx.env.STLIB_PATCH1 = [%s]\n\n", indent,stlibs
  }
  {print}
  ' wscript > /tmp/wscript &&
  mv -f /tmp/wscript wscript ||
  return 1
}

if [ ${mpv} -ne 0 ] && need_rebuild "${SOURCEDIR}/mpv/build/mpv"; then
  rm -f "${SOURCEDIR}/mpv/build/mpv"

	cd ${SOURCEDIR}
	
	if [ ! -d mpv ] ; then
		git clone -b master --depth 1 https://github.com/mpv-player/mpv.git
    tar -zcf mpv-$(date +%Y%m%d-%H%M%S).tar.gz mpv
		cd mpv
    PATCH1 || { echo "failed patching waf script (PATCH1)" >&2; exit 1; }

	else
		cd mpv
		#git pull --rebase --ff-only		
	fi
	./bootstrap.py
	if which waf ; then waf='waf' ; fi
	[ -f waf ] && waf='./waf'
	${waf} --help &>../../mpv.help
	
	MPVDIR=${ROOTDIR}/output-mpv
	mkdir -p "$MPVDIR"
	
	#mpvopt='--disable-cdda'
	
  if [ "${mpv}" -lt 2 ]; then
	  env PATH="$BUILDDIR/bin:$PATH" LD_LIBRARY_PATH="${BUILDDIR}/lib:$LD_LIBRARY_PATH" PKG_CONFIG_PATH="${BUILDDIR}/lib/pkgconfig" \
	  ${waf} configure --prefix="$MPVDIR" ${mpvopt} &>../../mpv.configure
	  ${waf} clean
  fi
	env PATH="$BUILDDIR/bin:$PATH" LD_LIBRARY_PATH="${BUILDDIR}/lib:$LD_LIBRARY_PATH" PKG_CONFIG_PATH="${BUILDDIR}/lib/pkgconfig" \
	${waf} build
	if [ -f "${SOURCEDIR}/mpv/build/mpv" ] ; then
		echo "OK. mpv compiled !"
		strip --strip-unneeded ${SOURCEDIR}/mpv/build/mpv
		${waf} install
	fi
	
else
	if [ "$mpv" ] ; then
		echo '-----------------------------------------------'
		echo "To force mpv recompile, remove: ${SOURCEDIR}/mpv/build/mpv"
		echo '-----------------------------------------------'
	fi
fi

smplayer=0 #0 to disable
if [ "${smplayer}" = 1 ] && [ ! -f "${SOURCEDIR}/smplayer/build/smplayer" ] ; then
  cd "${SOURCEDIR}" &&
  if [ ! -d smplayer ]; then
    svn co https://subversion.assembla.com/svn/smplayer/smplayer/trunk/ smplayer
    tar -zcf smplayer-$(date +%Y%m%d-%H%M%S).tar.gz smplayer
  fi
  cd smplayer
fi

cd ${ROOTDIR}

### END ###
