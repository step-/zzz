#!/bin/bash
#20150812

#####################################################################################
#								config
#####################################################################################

# One target at the time!
# You can pass the target on the command line, i.e., ffmpeg_project.sh mpv
# or change the default target below.
build=${1:-ffmpeg} #ffmpeg mpv spek aegisub

# On FIRST build ffmpeg=2 and mpv=2 do run configure as well.
# On subsequent builds 0, 1 or 2 work as follows:
ffmpeg=2   #0:disable 1:configure&build-all 2:build-changes-only
mpv=2      #0:disable 1:configure&build-all 2:build-changes-only
spek=0     #0:disable 1:WIP
aegisub=0  #0:disable 1:WIP

case ${build} in # This is why one target at the time.
	mpv) 	   ffpreset=mpv    		;;
	ffmpeg)	 ffpreset=ffmpeg 		;;
	aegisub) ffpreset=minimallibav	;;
	spek)    ffpreset=minimallibav	;;
  *) echo "Error: unknown build target or multiple targets not allowed." >&2
     exit 1
esac

echo "============================"
echo "	build=$build"
echo "============================"

#####################################################################################

scriptdir=${0%/*}
scriptfile=${0##*/}

case $scriptdir in
	 .*)  DIR=${PWD}       ;;
	 /*)  DIR=${scriptdir} ;;
	  *)  DIR=${scriptdir} ;;
esac

cd "$DIR"

export ROOTDIR="$DIR"
export BUILDDIR="$DIR/build"
export SOURCEDIR="$DIR/sources"

mkdir -p "$BUILDDIR/bin" "$BUILDDIR/lib/pkgconfig" "$BUILDDIR/include"
mkdir -p "$SOURCEDIR"

####################################################################################

wget='wget -c --no-check-certificate'

export PATH="$BUILDDIR/bin:$PATH"
export LD_LIBRARY_PATH="${BUILDDIR}/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="${BUILDDIR}/lib/pkgconfig:$PKG_CONFIG_PATH"

function EXECENV() {
	env PATH="$BUILDDIR/bin:$PATH" LD_LIBRARY_PATH="${BUILDDIR}/lib:$LD_LIBRARY_PATH" PKG_CONFIG_PATH="${BUILDDIR}/lib/pkgconfig" \
		eval $@
}

function StandardBuild() {
	./configure --prefix="$BUILDDIR" --disable-shared --enable-static && make && make install
}

####################################################################################

if [ ! -f "$BUILDDIR/bin/nasm" ] ; then #assembler
	cd ${SOURCEDIR}
	${wget} http://www.nasm.us/pub/nasm/releasebuilds/2.11.08/nasm-2.11.08.tar.xz
	tar Jxf nasm-2.11.08.tar.xz ; cd nasm-2.11.08
	./configure --prefix="$BUILDDIR" --bindir="$BUILDDIR/bin" && make && make install
fi

if [ ! -f "$BUILDDIR/bin/yasm" ] ; then #assembler
	cd ${SOURCEDIR}
	${wget} http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz
	tar xzvf yasm-1.3.0.tar.gz ; cd yasm-1.3.0
	./configure --prefix="$BUILDDIR" --bindir="$BUILDDIR/bin" && make && make install
fi

####################################################################################

#if [ ! -f "$BUILDDIR/lib/libbz2.a" ] ; then #basic lib
#	cd ${SOURCEDIR}
#	${wget} http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz
#	tar zxf bzip2-1.0.6.tar.gz ; cd bzip2-1.0.6 
#	sed -i "s|^PREFIX=.*|PREFIX=${BUILDDIR}|" Makefile && make && make install
#fi

#if [ ! -f "$BUILDDIR/lib/liblzma.a" ] ; then #basic lib
#	cd ${SOURCEDIR}
#	${wget} http://tukaani.org/xz/xz-5.2.1.tar.gz
#	tar zxf xz-5.2.1.tar.gz ; cd xz-5.2.1
#	./configure --prefix="$BUILDDIR" --disable-shared --enable-static && make && make install
#fi

# build libexpat.a first. Fatdog64 note: OS includes and links libexpat.so, which is OK.
if [ ! -f "$BUILDDIR/lib/libexpat.a" ] ; then #basic lib
	cd ${SOURCEDIR}
	${wget} http://sourceforge.net/projects/expat/files/expat/2.1.0/expat-2.1.0.tar.gz
	tar xzvf expat-2.1.0.tar.gz ; cd expat-2.1.0 
	./configure --prefix="$BUILDDIR" --disable-shared --enable-static && make && make install
fi

# Fatdog64: build libjpeg.a first. Fatdog64 note: OS includes and links libjpeg.8.1.so, which is OK.
# When linking mpv the linker links libv4lconvert.so which depends on libjpeg.*.so.
if [ ! -f "$BUILDDIR/lib/libjpeg.a" ] ; then
	cd ${SOURCEDIR}
	${wget} http://ijg.org/files/jpegsrc.v9a.tar.gz
	tar zxf jpegsrc.v9a.tar.gz ; cd jpeg-9a
	./configure --prefix="$BUILDDIR" --disable-shared --enable-static && make && make install
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

#libpng16 http://sourceforge.net/projects/libpng/files/libpng16/1.6.18/libpng-1.6.18.tar.xz/download

#if [ ! -f "$BUILDDIR/lib/libharfbuzz.a" ] ; then #libass
#	cd ${SOURCEDIR} 
#	${wget} http://www.freedesktop.org/software/harfbuzz/release/harfbuzz-1.0.1.tar.bz2 #2015-07-27
#	tar jxf harfbuzz-1.0.1.tar.bz2 ; cd harfbuzz-1.0.1
#	./configure --prefix="$BUILDDIR" --disable-shared --enable-static --without-icu --without-uniscribe --without-coretext --without-cairo && make && make install
#fi
if [ ! -f "$BUILDDIR/lib/libenca.a" ] ; then #libass
	cd ${SOURCEDIR}
	${wget} http://dl.cihar.com/enca/enca-1.16.tar.gz
	tar zxf enca-1.16.tar.gz ; cd enca-1.16
	./configure --prefix="$BUILDDIR" --disable-shared --enable-static && make && make install
fi
if [ ! -f "$BUILDDIR/lib/libfribidi.a" ] ; then #libass
	cd ${SOURCEDIR}
	${wget} http://fribidi.org/download/fribidi-0.19.7.tar.bz2 
	tar jxf fribidi-0.19.7.tar.bz2 ; cd fribidi-0.19.7
	./configure --prefix="$BUILDDIR" --disable-shared --enable-static && make && make install
fi
if [ ! -f "$BUILDDIR/lib/libass.a" ] ; then #ffmpeg, mpv, aegisub	
	cd ${SOURCEDIR}
	${wget} https://github.com/libass/libass/releases/download/0.12.3/libass-0.12.3.tar.gz
	tar -zxf libass-0.12.3.tar.gz ; cd libass-0.12.3
	./configure --prefix="$BUILDDIR" --disable-shared --enable-static && make && make install
fi

if [ ! -f "$BUILDDIR/lib/libluajit-5.1.a" ] ; then #mpv aegisub
	cd ${SOURCEDIR}
	${wget} http://luajit.org/download/LuaJIT-2.0.4.tar.gz #2015-05-14
	tar zxf LuaJIT-2.0.4.tar.gz ; cd LuaJIT-2.0.4
	sed -i "s| PREFIX=.*| PREFIX=${BUILDDIR}|" Makefile
	make && make install
	rm -v $BUILDDIR/lib/libluajit-5.1.so*
fi


################################################################################
#					ffmpeg exclusive stuff
################################################################################

if [ "$build" = "ffmpeg"  ] ; then
	if [ ! -f "$BUILDDIR/lib/libx264.a" ] ; then #ffmpeg
		cd ${SOURCEDIR}
		${wget} http://download.videolan.org/pub/x264/snapshots/last_x264.tar.bz2
		tar xjvf last_x264.tar.bz2
		cd x264-snapshot*
		./configure --prefix="$BUILDDIR" --bindir="$BUILDDIR/bin" --enable-static && make && make install
	fi

	if [ ! -f "$BUILDDIR/lib/libx265.a" ] ; then #ffmpeg
		cd ${SOURCEDIR}
		hg clone https://bitbucket.org/multicoreware/x265 #hg = mercurial (https://mercurial.selenic.com/)
		cd ${SOURCEDIR}/x265/build/linux
		cmake -DCMAKE_INSTALL_PREFIX="$BUILDDIR" -DENABLE_SHARED:bool=off ../../source
		make && make install
	fi

	if [ ! -f "$BUILDDIR/lib/libfdk-aac.a" ] ; then #ffmpeg
		cd ${SOURCEDIR}
		${wget} -O fdk-aac.tar.gz https://github.com/mstorsjo/fdk-aac/tarball/master
		tar xzvf fdk-aac.tar.gz ; cd mstorsjo-fdk-aac*
		autoreconf -fiv ; ./configure --prefix="$BUILDDIR" --disable-shared && make && make install
	fi

	if [ ! -f "$BUILDDIR/lib/libmp3lame.a" ] ; then #ffmpeg
		cd ${SOURCEDIR}
		curl -L -o lame-3.99.5.tar.gz http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz
		tar xzvf lame-3.99.5.tar.gz ; cd lame-3.99.5
		./configure --prefix="$BUILDDIR" --enable-nasm --disable-shared && make && make install
	fi

	if [ ! -f "$BUILDDIR/lib/libopus.a" ] ; then #ffmpeg
		cd ${SOURCEDIR}
		${wget} http://downloads.xiph.org/releases/opus/opus-1.1.tar.gz
		tar xzvf opus-1.1.tar.gz ; cd opus-1.1
		./configure --prefix="$BUILDDIR" --disable-shared && make && make install
	fi

	if [ ! -f "$BUILDDIR/lib/libvpx.a" ] ; then #ffmpeg
		cd ${SOURCEDIR}
		${wget} http://storage.googleapis.com/downloads.webmproject.org/releases/webm/libvpx-1.4.0.tar.bz2
		tar xjvf libvpx-1.4.0.tar.bz2
		cd libvpx-1.4.0
		./configure --prefix="$BUILDDIR" --disable-examples --disable-unit-tests && make && make install
	fi

	if [ ! -f "$BUILDDIR/lib/libvorbis.a" ] ; then #ffmpeg
		cd ${SOURCEDIR}
		${wget} http://downloads.xiph.org/releases/ogg/libogg-1.3.2.tar.gz
		tar -zxf libogg-1.3.2.tar.gz
		cd libogg-1.3.2
		./configure --prefix="$BUILDDIR" --disable-shared --enable-static && make && make install
		cd ${SOURCEDIR}
		${wget} http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.5.tar.gz
		tar -zxf libvorbis-1.3.5.tar.gz
		cd libvorbis-1.3.5
		./configure --prefix="$BUILDDIR" --disable-shared --enable-static && make && make install
	fi

	if [ ! -f "$BUILDDIR/lib/libtheora.a" ] ; then #ffmpeg
		cd ${SOURCEDIR}
		${wget} http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.bz2
		tar -jxf libtheora-1.1.1.tar.bz2 ; cd libtheora-1.1.1
    # --disable-examples otherwise example png2theora.c fails and so the does overall make
		./configure --prefix="$BUILDDIR" --disable-shared --enable-static --disable-examples && make && make install
	fi

	if [ ! -f "$BUILDDIR/lib/libxvidcore.a" ] ; then #ffmpeg
		cd ${SOURCEDIR}
		${wget} http://downloads.xvid.org/downloads/xvidcore-1.3.4.tar.gz
		tar -zxf xvidcore-1.3.4.tar.gz
		cd xvidcore/build/generic
		./configure --prefix="$BUILDDIR" --disable-shared --enable-static && make && make install
		rm -v $BUILDDIR/lib/libxvidcore.so*	
	fi

	if [ ! -f "$BUILDDIR/lib/libsoxr.a" ] ; then #ffmpeg
		cd ${SOURCEDIR}
		curl -L -o soxr-0.1.1-Source.tar.xz http://sourceforge.net/projects/soxr/files/soxr-0.1.1-Source.tar.xz/download
		tar -Jxf soxr-0.1.1-Source.tar.xz ; cd soxr-0.1.1-Source
		cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$BUILDDIR" -DBUILD_SHARED_LIBS="OFF" .
		make && make install
	fi

	if [ ! -f "$BUILDDIR/lib/libFLAC.a" ] ; then #ffmpeg
		cd ${SOURCEDIR}
		${wget} http://downloads.xiph.org/releases/flac/flac-1.3.1.tar.xz
		tar -Jxf flac-1.3.1.tar.xz ; cd flac-1.3.1
		./configure --prefix="$BUILDDIR" --disable-shared --enable-static --with-ogg="${BUILDDIR}/lib/libogg.a"
		make && make install
	fi

	if [ ! -f "$BUILDDIR/lib/libspeex.a" ] ; then #ffmpeg
		cd ${SOURCEDIR}
		${wget} http://downloads.xiph.org/releases/speex/speex-1.2rc1.tar.gz
		tar -zxf speex-1.2rc1.tar.gz
		cd speex-1.2rc1
		./configure --prefix="$BUILDDIR" --disable-shared --enable-static && make && make install
	fi

	if [ ! -f "$BUILDDIR/lib/libopenjp2.a" ] ; then #?
		cd ${SOURCEDIR}
		${wget} -O openjpeg.tar.gz https://github.com/uclouvain/openjpeg/tarball/master
		tar xzvf openjpeg.tar.gz
		cd uclouvain-openjpeg*
		cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$BUILDDIR" -DBUILD_SHARED_LIBS="OFF" .
		make && make install
	fi

	if [ ! -f "$BUILDDIR/lib/libopencore-amrnb.a" ] ; then #ffmpeg
		cd ${SOURCEDIR}
		curl -L -o opencore-amr-0.1.3.tar.gz http://sourceforge.net/projects/opencore-amr/files/opencore-amr/opencore-amr-0.1.3.tar.gz/download
		tar xzvf opencore-amr-0.1.3.tar.gz ; cd opencore-amr-0.1.3
		./configure --prefix="$BUILDDIR" --disable-shared --enable-static && make && make install
	fi

	if [ ! -f "$BUILDDIR/lib/libwavpack.a" ] ; then #ffmpeg
		cd ${SOURCEDIR}
		${wget} http://www.wavpack.com/wavpack-4.75.0.tar.bz2
		tar xjvf wavpack-4.75.0.tar.bz2 ; cd wavpack-4.75.0
		./configure --prefix="$BUILDDIR" --disable-shared --enable-static && make && make install 
	fi

	if [ ! -f "$BUILDDIR/lib/libvo-aacenc.a" ] ; then #ffmpeg
		cd ${SOURCEDIR}
		${wget} http://sourceforge.net/projects/opencore-amr/files/vo-aacenc/vo-aacenc-0.1.3.tar.gz
		tar xzvf vo-aacenc-0.1.3.tar.gz
		cd vo-aacenc-0.1.3
		./configure --prefix="$BUILDDIR" --disable-shared --enable-static && make && make install
	fi

fi

#########################################################################################
#			mpv exclusive stuff
#########################################################################################

if [ "$build" = "mpv"  ] ; then

	if [ ! -f "$BUILDDIR/lib/libcddb.a" ] ; then #libcdio
		cd ${SOURCEDIR}
		${wget} http://prdownloads.sourceforge.net/libcddb/libcddb-1.3.2.tar.bz2
		tar xjvf libcddb-1.3.2.tar.bz2 
		cd libcddb-1.3.2
		./configure --prefix="$BUILDDIR" --disable-shared --enable-static --without-cdio 
		sed -i 's|.*#undef HAVE_ICONV.*|#define HAVE_ICONV 1|' config.h
		make && make install
	fi
	if [ ! -f "$BUILDDIR/lib/libcdio.a" ] ; then #libcdio
		cd ${SOURCEDIR}
		${wget} http://ftp.gnu.org/gnu/libcdio/libcdio-0.93.tar.bz2
		tar xjvf libcdio-0.93.tar.bz2 ; cd libcdio-0.93
		./configure --prefix="$BUILDDIR" --disable-shared --enable-static --without-cd-drive
		sed -i 's|.*#undef HAVE_ICONV.*|#define HAVE_ICONV 1|' config.h
		make && make install
	fi
	if [ ! -f "$BUILDDIR/lib/libcdio_paranoia.a" ] ; then #libcdio #mpv ### http://www.linuxfromscratch.org/blfs/view/svn/multimedia/libcdio.html
		cd ${SOURCEDIR}
		${wget} http://ftp.gnu.org/gnu/libcdio/libcdio-paranoia-10.2+0.93+1.tar.bz2
		tar xjvf libcdio-paranoia-10.2+0.93+1.tar.bz2 ; cd libcdio-paranoia-10.2+0.93+1
		./configure --prefix="$BUILDDIR" --disable-shared --enable-static 
		sed -i 's|.*#undef HAVE_ICONV.*|#define HAVE_ICONV 1|' config.h
		make && make install
	fi

	if [ ! -f "$BUILDDIR/lib/libdvdcss.a" ] ; then #libdvdnav
		cd ${SOURCEDIR}
		${wget} http://download.videolan.org/pub/videolan/libdvdcss/1.3.99/libdvdcss-1.3.99.tar.bz2
		tar xjf libdvdcss-1.3.99.tar.bz2 ; cd libdvdcss-1.3.99 
		./configure --prefix="$BUILDDIR" --disable-shared --enable-static && make && make install
		cd ${SOURCEDIR}
	fi
	if [ ! -f "$BUILDDIR/lib/libdvdread.a" ] ; then #libdvdnav
		${wget} http://download.videolan.org/pub/videolan/libdvdread/5.0.3/libdvdread-5.0.3.tar.bz2
		tar xjf libdvdread-5.0.3.tar.bz2 ; cd libdvdread-5.0.3
		./configure --prefix="$BUILDDIR" --disable-shared --enable-static && make && make install
		cd ${SOURCEDIR}
	fi
	if [ ! -f "$BUILDDIR/lib/libdvdnav.a" ] ; then #mpv
		${wget} http://download.videolan.org/pub/videolan/libdvdnav/5.0.3/libdvdnav-5.0.3.tar.bz2
		tar xjf libdvdnav-5.0.3.tar.bz2 ; cd libdvdnav-5.0.3
		./configure --prefix="$BUILDDIR" --disable-shared --enable-static && make && make install
	fi

	if [ ! -f "$BUILDDIR/lib/libbluray.a" ] ; then #mpv
		#cd ${SOURCEDIR}
		#${wget} ftp://xmlsoft.org/libxml2/libxml2-2.9.2.tar.gz
		#tar zxf libxml2-2.9.2.tar.gz ; cd libxml2-2.9.2
		#./configure --prefix="$BUILDDIR" --disable-shared --enable-static --without-python && make && make install
		cd ${SOURCEDIR}
		${wget} http://download.videolan.org/pub/videolan/libbluray/0.8.1/libbluray-0.8.1.tar.bz2
		tar xjf libbluray-0.8.1.tar.bz2 ; cd libbluray-0.8.1
		./configure --prefix="$BUILDDIR" --disable-shared --enable-static --disable-bdjava --enable-udf --without-libxml2
		make clean && make && make install
	fi

	##linking problems
	#if [ ! -f "$BUILDDIR/lib/libguess.a" ] ; then #mpv
	#	cd ${SOURCEDIR}
	#	git clone -b master --depth 1 https://github.com/kaniini/libguess.git
	#	cd libguess 
	#	./autogen.sh
	#	./configure --prefix="$BUILDDIR" && make && make install
	#	rm -v $BUILDDIR/lib/libguess.so*
	#fi

	##linking problems
	#if [ ! -f "$BUILDDIR/lib/libuchardet.a" ] ; then #mpv
	#	cd ${SOURCEDIR}
	#	git clone -b master --depth 1 https://github.com/BYVoid/uchardet ; cd uchardet 
	#	cmake -DCMAKE_INSTALL_PREFIX="$BUILDDIR" . && make && make install
	#	rm -v $BUILDDIR/lib/libuchardet.so*
	#fi

fi

#########################################################################################
#			aegisub exclusive stuff
#########################################################################################

if [ "$build" = "aegisub"  ] ; then
	echo -n
fi

##########################################################################################

####################
#	cd ${SOURCEDIR}
#	${wget} http://www.openssl.org/source/openssl-1.0.2d.tar.gz
#	tar xzvf openssl-1.0.2d.tar.gz
#	cd openssl-1.0.2d
#	./config --prefix=/usr --openssldir=/etc/ssl --libdir=lib shared zlib-dynamic &&
#	./configure --prefix="$BUILDDIR" --disable-shared --enable-static
#	make && make install
####################

#####################################################################################

#fix prefix for built packages (in case of path change)
[ -e  "${BUILDDIR}/lib/pkgconfig" ] &&
  sed -i "s|^prefix=.*|prefix=${BUILDDIR}|" "${BUILDDIR}/lib/pkgconfig/"*
if ls "${BUILDDIR}/lib/"*.la >/dev/null 2>&1; then
  sed -i "s|^libdir=.*|libdir=${BUILDDIR}/lib|" ${BUILDDIR}/lib/*.la
  sed -i "s|^prefix=.*|libdir=${BUILDDIR}/lib|" ${BUILDDIR}/lib/*.la #fix damaged lines, if any
fi

# Naive dependency checker - it tests for $1-bin to be newer than ALL libs *.a
# A more accurate check would entail checking bin just against the
# true dependency libs, like make does.  Nevertheless, need_rebuild
# still saves us build time when all we're doing is adding/updating a
# couple of libs. By setting ffmpeg=2 / mpv=2 and using need_rebuild
# further down we don't end up reconfiguring and recompiling ffmpeg/mpv
# completely; we just relink them.
need_rebuild () { # $1-target-path
  [ ! -e "$1" ] && return 0
  local latest
  latest=$(ls -t "$1" "${BUILDDIR}/lib/"*.a 2>/dev/null | head -1)
  [ "$(basename "$1")" != "$(basename "${latest}")" ]
}

#####################################################################################

if ! [ "${build##*ffmpeg}" = "${build}" ]; then #lazy indent
if [ "$ffmpeg" -ne 0 ] && need_rebuild "$SOURCEDIR/ffmpeg/ffmpeg"; then
	rm -f "$SOURCEDIR/ffmpeg/ffmpeg"

	cd ${SOURCEDIR}

	if [ ! -d ffmpeg ] ; then
		git clone -b master --depth 1 git://source.ffmpeg.org/ffmpeg.git
		tar -zcf ffmpeg-$(date +%Y%m%d-%H%M%S).tar.gz ffmpeg
	else
		echo '-------------------------------------------'
		echo "To redownload latest git: rm '$PWD/ffmpeg'"
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
	basicav='--enable-libfdk-aac --enable-libx264 --enable-libmp3lame --enable-libxvid'
	extraaudio='--enable-libvorbis --enable-libspeex --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libwavpack --enable-libopus'
	extravideo='--enable-libvpx --enable-libtheora --enable-libx265 --enable-libxvid'

	if [ ! "$ffpreset" ] ; then
		ffpreset=mpv #limitedffmpeg mpv minimallibav
	fi
	echo "ffpreset: $ffpreset"

	case "$ffpreset" in
	  ffmpeg)
			echo ""
			;;
	  limitedffmpeg)
			extra='--disable-ffserver --disable-ffplay --disable-sdl'
			;;
	  mpv)
			basicav=''
			extraaudio=''
			extravideo=''
			extra='--disable-ffserver --disable-ffprobe --disable-ffplay --disable-sdl'
			extra2='--enable-openssl --disable-encoders --disable-muxers'
			;;
	  minimallibav)
			basicav=''
			extraaudio=''
			extravideo=''
			extra='--disable-ffserver --disable-ffprobe --disable-ffplay --disable-sdl'
			extra2='--disable-network --disable-encoders --disable-muxers --disable-bsfs --disable-filters' 
			;;
	esac

	./configure --help >../../ffmpeg.help

	if [ -f config.h ] ; then
		echo '-----------------------------------------'
		echo "To force reconfigure: rm '$PWD/config.h'"
		echo '-----------------------------------------'
		ffconfig='echo'
	else
		ffredir='&>../../ffmpeg.configure'
	fi

	[ "$staticlib" ] && echo "--- Will build ffmpeg static libs" && echo

	if [ ${ffmpeg} -lt 2 -o ! -e config.mak ]; then
	  eval ${ffconfig} ./configure \
		  --prefix="$BUILDDIR" ${xbc} ${xlib} ${doc} \
		  --pkg-config-flags="--static" ${staticlib} \
		  --extra-cflags="-I${BUILDDIR}/include" \
		  --extra-ldflags="-L${BUILDDIR}/lib" \
		  --bindir="${BUILDDIR}/bin" \
		  ${licenses} ${basic} ${basicav} ${extraaudio} ${extravideo} ${extra} ${extra2} ${ffredir}
		[ $? -ne 0 ] && echo 'ERROR' && exit 1
	fi
#	make
#	[ $? -ne 0 ] && make # Why making again on error ??
#	make install
  make && make install && {
	  ffmpegout="$DIR/output-ffmpeg"
	  mkdir -p "$ffmpegout"
	  [ -f "$SOURCEDIR/ffmpeg/ffmpeg" ] && cp -v "$SOURCEDIR/ffmpeg/ffmpeg" "$ffmpegout"
	  [ -f "$SOURCEDIR/ffmpeg/ffplay" ] && cp -v "$SOURCEDIR/ffmpeg/ffplay" "$ffmpegout"
	  [ -f "$SOURCEDIR/ffmpeg/ffprobe" ] && cp -v "$SOURCEDIR/ffmpeg/ffprobe" "$ffmpegout"
	  [ -f "$SOURCEDIR/ffmpeg/ffserver" ] && cp -v "$SOURCEDIR/ffmpeg/ffserver" "$ffmpegout"

	  #find "$SOURCEDIR/ffmpeg" -type f | grep -v "\.h$" | while read file ; do rm -rf $file ; done
	  #find "$SOURCEDIR/ffmpeg" -maxdepth 1 -type d | grep -v "^${SOURCEDIR}/ffmpeg$" | grep -v lib | while read dir ; do rm -rfv $dir ; done
	  #cp -rfv $SOURCEDIR/ffmpeg/* "${BUILDDIR}/include"
  }

else
	if [ -f "$SOURCEDIR/ffmpeg/ffmpeg" ] ; then
		echo '-----------------------------------------------'
		echo "To force ffmpeg recompile: rm '${SOURCEDIR}/ffmpeg/ffmpeg'"
		echo '-----------------------------------------------'
	fi
fi
fi #lazy indent

####################################################################################

if ! [ "${build##*spek}" = "${build}" ]; then
	if [ ${spek} -eq 1 ] ; then
	  cd ${SOURCEDIR}
	  ${wget} https://spek.googlecode.com/files/spek-0.8.2.tar.xz
	  tar Jxf spek-0.8.2.tar.xz ; cd spek-0.8.2
	  mkdir ${ROOTDIR}/output-spek
	  ./configure --prefix=${ROOTDIR}/output-spek && make && make install
	  exit $?
	fi
fi

####################################################################################

if ! [ "${build##*aegisub}" = "${build}" ]; then
  if [ ${aegisub} -eq 1 ] ; then
	  echo -n
	  exit $?
  fi
fi

####################################################################################
#									mpv
####################################################################################

PATCH1 () {
  # Proceed on Fatdog64 only (test for '_fatdog' in script name)
  if [ "${0%%*_fatdog}" = "$0" ]; then
    echo "Skip PATCH1 (not Fatdog64)" >&2
    return 0
  fi
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

if ! [ "${build##*mpv}" = "${build}" ]; then #lazy indent
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
	if which waf 2>/dev/null ; then waf='waf' ; fi
	[ -f waf ] && waf='./waf'
	${waf} --help &>../../mpv.help

	MPVDIR=${ROOTDIR}/output-mpv
	mkdir -p "$MPVDIR"

	#mpvopt='--disable-cdda'

	if [ "${mpv}" -lt 2 -o ! -e build/config.h ]; then
	  ${waf} configure --prefix="$MPVDIR" ${mpvopt} &>../../mpv.configure
	  ${waf} clean
	fi
	${waf} build
	if [ -f "${SOURCEDIR}/mpv/build/mpv" ] ; then
		echo "OK. mpv compiled !"
		strip --strip-unneeded ${SOURCEDIR}/mpv/build/mpv
		${waf} install
	fi

else
	if [ "$mpv" ] ; then
		echo '-----------------------------------------------'
		echo "To force mpv recompile: rm '${SOURCEDIR}/mpv/build/mpv'"
		echo '-----------------------------------------------'
	fi
fi
fi #lazy indent

cd ${ROOTDIR}

### END ###
