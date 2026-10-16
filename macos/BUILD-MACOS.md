# Build auf macOS (Apple Silicon) – do1xx-Fork

Fork-Stand: upstream master + PR #48 (TEA1/2/3-Keys, noch offen upstream).
Getestet 16.10.2026: SDR++ master `8c9f5ee8` (v1.3.0), macOS 26.6, M-Serie.

Das Plugin MUSS gegen denselben SDR++-Core gebaut werden wie die App (ABI).

```bash
B=~/Projects/sdrpp-tetra
# 1. SDR++ bauen (Pluto: in source_modules/plutosdr_source/CMakeLists.txt die Darwin-Abfrage
#    um 'AND EXISTS "/Library/Frameworks/iio.framework"' ergänzen -> nutzt brew-libiio via pkg-config)
cd $B/SDRPlusPlus && mkdir -p build && cd build
cmake .. -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_BUILD_TYPE=Release -DUSE_BUNDLE_DEFAULTS=ON \
  -DOPT_BUILD_PLUTOSDR_SOURCE=ON -DOPT_BUILD_BLADERF_SOURCE=ON -DOPT_BUILD_USRP_SOURCE=ON \
  -DOPT_BUILD_SDRPLAY_SOURCE=OFF -DOPT_BUILD_LIMESDR_SOURCE=OFF -DOPT_BUILD_AUDIO_SINK=OFF \
  -DOPT_BUILD_PORTAUDIO_SINK=ON -DOPT_BUILD_NEW_PORTAUDIO_SINK=ON -DOPT_BUILD_M17_DECODER=OFF \
  -DOPT_BUILD_PERSEUS_SOURCE=OFF -DOPT_BUILD_AUDIO_SOURCE=OFF -DOPT_BUILD_RFNM_SOURCE=OFF \
  -DOPT_BUILD_FOBOSSDR_SOURCE=OFF -DOPT_BUILD_HYDRASDR_SOURCE=OFF -DOPT_BUILD_DRAGONLABS_SOURCE=OFF
make -j10

# 2. ETSI-Codec (md5sum gibt es unter macOS in /sbin)
cd $B/sdrpp-tetra-demodulator/src/decoder/etsi_codec-patches && sh download_and_patch.sh

# 3. Plugin + Tests
cd $B/sdrpp-tetra-demodulator && mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON \
  -DSDRPP_CORE_ROOT=$B/SDRPlusPlus/core \
  -DSDRPP_CORE_LIB=$B/SDRPlusPlus/build/core/libsdrpp_core.dylib \
  -DSDRPP_MODULE_CMAKE=$B/sdrpp-tetra-demodulator/macos/sdrpp_module_macos.cmake
make -j10 && ctest

# 4. Bundle
cd $B/SDRPlusPlus && sh make_macos_bundle.sh build ../SDR++.app
sh -c '. macos/bundle_utils.sh; bundle_install_binary ../SDR++.app ../SDR++.app/Contents/Plugins ../sdrpp-tetra-demodulator/build/tetra_demodulator.dylib'
# libiio aus brew: Systemlibs wieder auf /usr/lib biegen
install_name_tool -change @rpath/libiconv.2.dylib /usr/lib/libiconv.2.dylib \
  -change @rpath/liblzma.5.dylib /usr/lib/liblzma.5.dylib \
  -change @rpath/libz.1.dylib /usr/lib/libz.1.dylib ../SDR++.app/Contents/Frameworks/libiio.0.dylib
codesign --force --deep -s - ../SDR++.app
```

Weitere Out-of-tree-Plugins (mirisdr_source, inmarsatc_demodulator) gleich bauen und per
`bundle_install_binary` einlegen; `libinmarsatc_decoder.dylib` aus /opt/homebrew/lib nach
`Contents/Frameworks` kopieren.
