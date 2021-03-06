#*****************************************************************************
# Copyright 2015-2019 Alexander Barthel alex@littlenavmap.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#****************************************************************************

# =============================================================================
# Set these environment variables for configuration - do not change this .pro file
# =============================================================================
#
# ATOOLS_INC_PATH
# Optional. Path to atools include. Default is "../atools/src" if not set.
# Also reads *.qm translation files from "$ATOOLS_INC_PATH/..".
#
# ATOOLS_LIB_PATH
# Optional. Path to atools static library. Default is "../build-atools-$${CONF_TYPE}"
# if not set.
#
# MARBLE_INC_PATH
# Required. Path to Marble include files of a Marble installation.
# Example: /home/YOU/Programs/Marble/include
#
# MARBLE_LIB_PATH
# Required. Path to Marble library files of a Marble installation.
# Example: /home/YOU/Programs/Marble/lib
# Also reads plugins from "$$MARBLE_LIB_PATH/../plugins" or "$$MARBLE_LIB_PATH/lib/plugins" depending on OS.
#
# INSTALL_MARBLE_DYLIB
# Required for macOS only. Path to the Marble shared library in the Marble build folder
# that was created by running "make all".
# Example: $HOME/Projekte/build-marble-$$CONF_TYPE/src/lib/marble/libmarblewidget-qt5.25.dylib
#
# OPENSSL_PATH
# Required for Windows only. Base path of WinSSL 1.0.1 installation (https://slproweb.com/products/Win32OpenSSL.html).
# Defaults to "C:\OpenSSL-Win32" if empty.
#
# ATOOLS_GIT_PATH
# Optional. Path to GIT executable. Revision will be set to "UNKNOWN" if not set.
# Uses "git" on macOS and Linux as default if not set.
# Example: "C:\Git\bin\git"
#
# ATOOLS_SIMCONNECT_PATH
# Path to SimConnect SDK. SimConnect support will be omitted in build if not set.
# Example: "C:\Program Files (x86)\Microsoft Games\Microsoft Flight Simulator X SDK\SDK\Core Utilities Kit\SimConnect SDK"
#
# DEPLOY_BASE
# Target folder for "make deploy". Optional. Default is "../deploy" plus project name ($$TARGET_NAME).
#
# DATABASE_BASE
# Source folder for database files that are copied into the distribution on deploy.
# Optional. Ignored if it does not exist. Default is "$$PWD/../little_navmap_db".
#
# HELP_BASE
# Source folder for additional help files that are copied into the distribution on deploy.
# Optional. Ignored if it does not exist. Default is "$$PWD/../little_navmap_help".
#
# ATOOLS_QUIET
# Optional. Set this to "true" to avoid qmake messages.
#
# =============================================================================
# End of configuration documentation
# =============================================================================

QT += core gui sql xml network svg printsupport

CONFIG += build_all c++14
CONFIG -= debug_and_release debug_and_release_target

TARGET = littlenavmap
TEMPLATE = app

TARGET_NAME=Little Navmap

# =======================================================================
# Copy ennvironment variables into qmake variables
ATOOLS_INC_PATH=$$(ATOOLS_INC_PATH)
ATOOLS_LIB_PATH=$$(ATOOLS_LIB_PATH)
MARBLE_INC_PATH=$$(MARBLE_INC_PATH)
MARBLE_LIB_PATH=$$(MARBLE_LIB_PATH)
INSTALL_MARBLE_DYLIB=$$(INSTALL_MARBLE_DYLIB)
OPENSSL_PATH=$$(OPENSSL_PATH)
GIT_PATH=$$(ATOOLS_GIT_PATH)
SIMCONNECT_PATH=$$(ATOOLS_SIMCONNECT_PATH)
DEPLOY_BASE=$$(DEPLOY_BASE)
DATABASE_BASE=$$(DATABASE_BASE)
HELP_BASE=$$(HELP_BASE)
QUIET=$$(ATOOLS_QUIET)

# =======================================================================
# Fill defaults for unset

CONFIG(debug, debug|release) : CONF_TYPE=debug
CONFIG(release, debug|release) : CONF_TYPE=release

isEmpty(DEPLOY_BASE) : DEPLOY_BASE=$$PWD/../deploy
isEmpty(DATABASE_BASE) : DATABASE_BASE=$$PWD/../little_navmap_db
isEmpty(HELP_BASE) : HELP_BASE=$$PWD/../little_navmap_help

isEmpty(ATOOLS_INC_PATH) : ATOOLS_INC_PATH=$$PWD/../atools/src
isEmpty(ATOOLS_LIB_PATH) : ATOOLS_LIB_PATH=$$PWD/../build-atools-$$CONF_TYPE

isEmpty(MARBLE_INC_PATH) : MARBLE_INC_PATH=$$PWD/../Marble-$$CONF_TYPE/include
isEmpty(MARBLE_LIB_PATH) : MARBLE_LIB_PATH=$$PWD/../Marble-$$CONF_TYPE/lib

win32: isEmpty(OPENSSL_PATH) : OPENSSL_PATH=C:\OpenSSL-Win32

# =======================================================================
# Set compiler flags and paths

unix:!macx {
  isEmpty(GIT_PATH) : GIT_PATH=git

  # Find OpenSSL location
  exists( /lib/x86_64-linux-gnu/libssl.so.1.0.0 ) :  OPENSSL_PATH=/lib/x86_64-linux-gnu
  exists( /usr/lib/x86_64-linux-gnu/libssl.so.1.0.0 ) : OPENSSL_PATH=/usr/lib/x86_64-linux-gnu
  QMAKE_LFLAGS += -no-pie

  # Makes the shell script and setting LD_LIBRARY_PATH redundant
  QMAKE_RPATHDIR=.
  QMAKE_RPATHDIR+=./lib

  # Search path for the Marble widget so while linking
  QMAKE_RPATHLINKDIR=$$MARBLE_LIB_PATH

  LIBS += -L$$MARBLE_LIB_PATH -lmarblewidget-qt5 -L$$ATOOLS_LIB_PATH -latools  -lz
}

win32 {
  WINDEPLOY_FLAGS = --compiler-runtime
  CONFIG(debug, debug|release) : WINDEPLOY_FLAGS += --debug
  CONFIG(release, debug|release) : WINDEPLOY_FLAGS += --release

  DEFINES += _USE_MATH_DEFINES

  CONFIG(debug, debug|release) : LIBS += -L$$MARBLE_LIB_PATH -llibmarblewidget-qt5d
  CONFIG(release, debug|release) : LIBS += -L$$MARBLE_LIB_PATH -llibmarblewidget-qt5
  LIBS += -L$$ATOOLS_LIB_PATH -latools -lz

  !isEmpty(SIMCONNECT_PATH) {
    DEFINES += SIMCONNECT_BUILD
    INCLUDEPATH += $$SIMCONNECT_PATH"\inc"
    LIBS += $$SIMCONNECT_PATH"\lib\SimConnect.lib"
  }
}

macx {
  isEmpty(GIT_PATH) : GIT_PATH=git

  # Compatibility down to OS X 10.10
  QMAKE_MACOSX_DEPLOYMENT_TARGET = 10.10

  LIBS += -L$$MARBLE_LIB_PATH -lmarblewidget-qt5 -L$$ATOOLS_LIB_PATH -latools  -lz
}

isEmpty(GIT_PATH) {
  GIT_REVISION='\\"UNKNOWN\\"'
} else {
  GIT_REVISION='\\"$$system('$$GIT_PATH' rev-parse --short HEAD)\\"'
}

PRE_TARGETDEPS += $$ATOOLS_LIB_PATH/libatools.a
DEPENDPATH += $$ATOOLS_INC_PATH $$MARBLE_INC_PATH
INCLUDEPATH += $$PWD/src $$ATOOLS_INC_PATH $$MARBLE_INC_PATH
DEFINES += GIT_REVISION=$$GIT_REVISION
DEFINES += QT_NO_CAST_FROM_BYTEARRAY
DEFINES += QT_NO_CAST_TO_ASCII

# =======================================================================
# Print values when running qmake

!isEqual(QUIET, "true") {
message(-----------------------------------)
message(GIT_PATH: $$GIT_PATH)
message(GIT_REVISION: $$GIT_REVISION)
message(OPENSSL_PATH: $$OPENSSL_PATH)
message(ATOOLS_INC_PATH: $$ATOOLS_INC_PATH)
message(ATOOLS_LIB_PATH: $$ATOOLS_LIB_PATH)
message(MARBLE_INC_PATH: $$MARBLE_INC_PATH)
message(MARBLE_LIB_PATH: $$MARBLE_LIB_PATH)
macx : message(MARBLE_BUILD_PATH: $$MARBLE_BUILD_PATH)
message(DEPLOY_BASE: $$DEPLOY_BASE)
message(DEFINES: $$DEFINES)
message(INCLUDEPATH: $$INCLUDEPATH)
message(LIBS: $$LIBS)
message(TARGET_NAME: $$TARGET_NAME)
message(QT_INSTALL_PREFIX: $$[QT_INSTALL_PREFIX])
message(QT_INSTALL_LIBS: $$[QT_INSTALL_LIBS])
message(QT_INSTALL_PLUGINS: $$[QT_INSTALL_PLUGINS])
message(QT_INSTALL_TRANSLATIONS: $$[QT_INSTALL_TRANSLATIONS])
message(QT_INSTALL_BINS: $$[QT_INSTALL_BINS])
message(CONFIG: $$CONFIG)
message(-----------------------------------)
}

# =====================================================================
# Files

SOURCES += \
  src/common/aircrafttrack.cpp \
  src/common/airportfiles.cpp \
  src/common/constants.cpp \
  src/common/coordinateconverter.cpp \
  src/common/elevationprovider.cpp \
  src/common/formatter.cpp \
  src/common/htmlinfobuilder.cpp \
  src/common/jumpback.cpp \
  src/common/mapcolors.cpp \
  src/common/mapflags.cpp \
  src/common/maptools.cpp \
  src/common/maptypes.cpp \
  src/common/maptypesfactory.cpp \
  src/common/proctypes.cpp \
  src/common/settingsmigrate.cpp \
  src/common/symbolpainter.cpp \
  src/common/tabindexes.cpp \
  src/common/textplacement.cpp \
  src/common/unit.cpp \
  src/common/unitstringtool.cpp \
  src/common/updatehandler.cpp \
  src/common/vehicleicons.cpp \
  src/connect/connectclient.cpp \
  src/connect/connectdialog.cpp \
  src/db/databasedialog.cpp \
  src/db/databaseerrordialog.cpp \
  src/db/databasemanager.cpp \
  src/db/dbtypes.cpp \
  src/export/csvexporter.cpp \
  src/export/exporter.cpp \
  src/export/htmlexporter.cpp \
  src/gui/airspacetoolbarhandler.cpp \
  src/gui/mainwindow.cpp \
  src/gui/stylehandler.cpp \
  src/gui/timedialog.cpp \
  src/gui/trafficpatterndialog.cpp \
  src/gui/updatedialog.cpp \
  src/info/infocontroller.cpp \
  src/main.cpp\
  src/mapgui/aprongeometrycache.cpp \
  src/mapgui/imageexportdialog.cpp \
  src/mapgui/mapfunctions.cpp \
  src/mapgui/maplayer.cpp \
  src/mapgui/maplayersettings.cpp \
  src/mapgui/mappaintwidget.cpp \
  src/mapgui/mapscale.cpp \
  src/mapgui/mapscreenindex.cpp \
  src/mapgui/maptooltip.cpp \
  src/mapgui/mapvisible.cpp \
  src/mapgui/mapwidget.cpp \
  src/mappainter/mappainter.cpp \
  src/mappainter/mappainteraircraft.cpp \
  src/mappainter/mappainterairport.cpp \
  src/mappainter/mappainterairspace.cpp \
  src/mappainter/mappainteraltitude.cpp \
  src/mappainter/mappainterils.cpp \
  src/mappainter/mappaintermark.cpp \
  src/mappainter/mappainternav.cpp \
  src/mappainter/mappainterroute.cpp \
  src/mappainter/mappaintership.cpp \
  src/mappainter/mappainteruser.cpp \
  src/mappainter/mappaintervehicle.cpp \
  src/mappainter/mappainterweather.cpp \
  src/mappainter/mappaintlayer.cpp \
  src/navapp.cpp \
  src/online/onlinedatacontroller.cpp \
  src/options/optiondata.cpp \
  src/options/optionsdialog.cpp \
  src/perf/aircraftperfcontroller.cpp \
  src/perf/aircraftperfdialog.cpp \
  src/print/printdialog.cpp \
  src/print/printsupport.cpp \
  src/profile/profilelabelwidget.cpp \
  src/profile/profilescrollarea.cpp \
  src/profile/profilewidget.cpp \
  src/query/airportquery.cpp \
  src/query/airspacequery.cpp \
  src/query/infoquery.cpp \
  src/query/mapquery.cpp \
  src/query/procedurequery.cpp \
  src/query/querytypes.cpp \
  src/route/flightplanentrybuilder.cpp \
  src/route/parkingdialog.cpp \
  src/route/route.cpp \
  src/route/routealtitude.cpp \
  src/route/routealtitudeleg.cpp \
  src/route/routecommand.cpp \
  src/route/routecontroller.cpp \
  src/route/routeexport.cpp \
  src/route/routeexportdata.cpp \
  src/route/routeexportdialog.cpp \
  src/route/routefinder.cpp \
  src/route/routeleg.cpp \
  src/route/routenetwork.cpp \
  src/route/routenetworkairway.cpp \
  src/route/routenetworkradio.cpp \
  src/route/routestring.cpp \
  src/route/routestringdialog.cpp \
  src/route/userwaypointdialog.cpp \
  src/search/abstractsearch.cpp \
  src/search/airporticondelegate.cpp \
  src/search/airportsearch.cpp \
  src/search/column.cpp \
  src/search/columnlist.cpp \
  src/search/navicondelegate.cpp \
  src/search/navsearch.cpp \
  src/search/onlinecentersearch.cpp \
  src/search/onlineclientsearch.cpp \
  src/search/onlineserversearch.cpp \
  src/search/proceduresearch.cpp \
  src/search/searchbasetable.cpp \
  src/search/searchcontroller.cpp \
  src/search/sqlcontroller.cpp \
  src/search/sqlmodel.cpp \
  src/search/sqlproxymodel.cpp \
  src/search/userdatasearch.cpp \
  src/search/usericondelegate.cpp \
  src/userdata/userdatacontroller.cpp \
  src/userdata/userdatadialog.cpp \
  src/userdata/userdataexportdialog.cpp \
  src/userdata/userdataicons.cpp \
  src/weather/weatherreporter.cpp \
  src/web/webcontroller.cpp \
  src/web/requesthandler.cpp \
  src/web/webmapcontroller.cpp \
    src/web/webtools.cpp \
    src/web/webflags.cpp \
    src/web/webapp.cpp

HEADERS  += \
  src/common/aircrafttrack.h \
  src/common/airportfiles.h \
  src/common/constants.h \
  src/common/coordinateconverter.h \
  src/common/elevationprovider.h \
  src/common/formatter.h \
  src/common/htmlinfobuilder.h \
  src/common/jumpback.h \
  src/common/mapcolors.h \
  src/common/mapflags.h \
  src/common/maptools.h \
  src/common/maptypes.h \
  src/common/maptypesfactory.h \
  src/common/proctypes.h \
  src/common/settingsmigrate.h \
  src/common/symbolpainter.h \
  src/common/tabindexes.h \
  src/common/textplacement.h \
  src/common/unit.h \
  src/common/unitstringtool.h \
  src/common/updatehandler.h \
  src/common/vehicleicons.h \
  src/connect/connectclient.h \
  src/connect/connectdialog.h \
  src/db/databasedialog.h \
  src/db/databaseerrordialog.h \
  src/db/databasemanager.h \
  src/db/dbtypes.h \
  src/export/csvexporter.h \
  src/export/exporter.h \
  src/export/htmlexporter.h \
  src/gui/airspacetoolbarhandler.h \
  src/gui/mainwindow.h \
  src/gui/stylehandler.h \
  src/gui/timedialog.h \
  src/gui/trafficpatterndialog.h \
  src/gui/updatedialog.h \
  src/info/infocontroller.h \
  src/mapgui/aprongeometrycache.h \
  src/mapgui/imageexportdialog.h \
  src/mapgui/mapfunctions.h \
  src/mapgui/maplayer.h \
  src/mapgui/maplayersettings.h \
  src/mapgui/mappaintwidget.h \
  src/mapgui/mapscale.h \
  src/mapgui/mapscreenindex.h \
  src/mapgui/maptooltip.h \
  src/mapgui/mapvisible.h \
  src/mapgui/mapwidget.h \
  src/mappainter/mappainter.h \
  src/mappainter/mappainteraircraft.h \
  src/mappainter/mappainterairport.h \
  src/mappainter/mappainterairspace.h \
  src/mappainter/mappainteraltitude.h \
  src/mappainter/mappainterils.h \
  src/mappainter/mappaintermark.h \
  src/mappainter/mappainternav.h \
  src/mappainter/mappainterroute.h \
  src/mappainter/mappaintership.h \
  src/mappainter/mappainteruser.h \
  src/mappainter/mappaintervehicle.h \
  src/mappainter/mappainterweather.h \
  src/mappainter/mappaintlayer.h \
  src/navapp.h \
  src/online/onlinedatacontroller.h \
  src/options/optiondata.h \
  src/options/optionsdialog.h \
  src/perf/aircraftperfcontroller.h \
  src/perf/aircraftperfdialog.h \
  src/print/printdialog.h \
  src/print/printsupport.h \
  src/profile/profilelabelwidget.h \
  src/profile/profilescrollarea.h \
  src/profile/profilewidget.h \
  src/query/airportquery.h \
  src/query/airspacequery.h \
  src/query/infoquery.h \
  src/query/mapquery.h \
  src/query/procedurequery.h \
  src/query/querytypes.h \
  src/route/flightplanentrybuilder.h \
  src/route/parkingdialog.h \
  src/route/route.h \
  src/route/routealtitude.h \
  src/route/routealtitudeleg.h \
  src/route/routecommand.h \
  src/route/routecontroller.h \
  src/route/routeexport.h \
  src/route/routeexportdata.h \
  src/route/routeexportdialog.h \
  src/route/routefinder.h \
  src/route/routeleg.h \
  src/route/routenetwork.h \
  src/route/routenetworkairway.h \
  src/route/routenetworkradio.h \
  src/route/routestring.h \
  src/route/routestringdialog.h \
  src/route/userwaypointdialog.h \
  src/search/abstractsearch.h \
  src/search/airporticondelegate.h \
  src/search/airportsearch.h \
  src/search/column.h \
  src/search/columnlist.h \
  src/search/navicondelegate.h \
  src/search/navsearch.h \
  src/search/onlinecentersearch.h \
  src/search/onlineclientsearch.h \
  src/search/onlineserversearch.h \
  src/search/proceduresearch.h \
  src/search/searchbasetable.h \
  src/search/searchcontroller.h \
  src/search/sqlcontroller.h \
  src/search/sqlmodel.h \
  src/search/sqlproxymodel.h \
  src/search/userdatasearch.h \
  src/search/usericondelegate.h \
  src/userdata/userdatacontroller.h \
  src/userdata/userdatadialog.h \
  src/userdata/userdataexportdialog.h \
  src/userdata/userdataicons.h \
  src/weather/weatherreporter.h \
  src/web/webcontroller.h \
  src/web/requesthandler.h \
  src/web/webmapcontroller.h \
    src/web/webtools.h \
    src/web/webflags.h \
    src/web/webapp.h

FORMS += \
  src/connect/connectdialog.ui \
  src/db/databasedialog.ui \
  src/db/databaseerrordialog.ui \
  src/gui/mainwindow.ui \
  src/gui/timedialog.ui \
  src/gui/trafficpatterndialog.ui \
  src/gui/updatedialog.ui \
  src/mapgui/imageexportdialog.ui \
  src/options/options.ui \
  src/perf/aircraftperfdialog.ui \
  src/print/printdialog.ui \
  src/route/parkingdialog.ui \
  src/route/routeexportdialog.ui \
  src/route/routestringdialog.ui \
  src/route/userwaypointdialog.ui \
  src/userdata/userdatadialog.ui \
  src/userdata/userdataexportdialog.ui

RESOURCES += \
  littlenavmap.qrc

ICON = resources/icons/littlenavmap.icns

TRANSLATIONS = littlenavmap_fr.ts \
               littlenavmap_it.ts \
               littlenavmap_nl.ts \
               littlenavmap_de.ts \
               littlenavmap_es.ts \
               littlenavmap_pt_BR.ts

OTHER_FILES += \
  $$files(build/*, true) \
  $$files(customize/*, true) \
  $$files(desktop/*, true) \
  $$files(etc/*, true) \
  $$files(help/*, true) \
  $$files(web/*, true) \
  $$files(magdec/*, true) \
  $$files(marble/*, true) \
  .travis.yml \
  .gitignore \
  *.ts \
  BUILD.txt \
  CHANGELOG.txt \
  LICENSE.txt \
  README.txt \
  README.md \
  htmltidy.cfg \
  uncrustify.cfg

# =====================================================================
# Local deployment commands for development

# Linux - Copy help and Marble plugins and data
unix:!macx {
  copydata.commands = mkdir -p $$OUT_PWD/plugins &&
  copydata.commands += cp -avfu \
    $$MARBLE_LIB_PATH/marble/plugins/libCachePlugin.so \
    $$MARBLE_LIB_PATH/marble/plugins/libCompassFloatItem.so \
    $$MARBLE_LIB_PATH/marble/plugins/libGraticulePlugin.so \
    $$MARBLE_LIB_PATH/marble/plugins/libKmlPlugin.so \
    $$MARBLE_LIB_PATH/marble/plugins/libLatLonPlugin.so \
    $$MARBLE_LIB_PATH/marble/plugins/libLicense.so \
    $$MARBLE_LIB_PATH/marble/plugins/libMapScaleFloatItem.so \
    $$MARBLE_LIB_PATH/marble/plugins/libNavigationFloatItem.so \
    $$MARBLE_LIB_PATH/marble/plugins/libOsmPlugin.so \
    $$MARBLE_LIB_PATH/marble/plugins/libOverviewMap.so \
    $$MARBLE_LIB_PATH/marble/plugins/libPn2Plugin.so \
    $$MARBLE_LIB_PATH/marble/plugins/libPntPlugin.so \
    $$OUT_PWD/plugins &&
  copydata.commands += mkdir -p $$OUT_PWD/translations &&
  copydata.commands += cp -avfu $$PWD/*.qm $$OUT_PWD/translations &&
  copydata.commands += cp -avfu $$ATOOLS_INC_PATH/../*.qm $$OUT_PWD/translations &&
  copydata.commands += cp -avfu $$PWD/help $$OUT_PWD &&
  copydata.commands += cp -avfu $$PWD/web $$OUT_PWD &&
  copydata.commands += cp -avfu $$PWD/customize $$OUT_PWD &&
  copydata.commands += cp -avfu $$PWD/magdec $$OUT_PWD &&
  copydata.commands += cp -avfu $$PWD/marble/data $$OUT_PWD &&
  copydata.commands += cp -vf $$PWD/desktop/littlenavmap*.sh $$OUT_PWD &&
  copydata.commands += chmod -v a+x $$OUT_PWD/littlenavmap*.sh
}

# Mac OS X - Copy help and Marble plugins and data
macx {
  copydata.commands += cp -Rv $$PWD/help $$OUT_PWD/littlenavmap.app/Contents/MacOS &&
  copydata.commands += cp -Rv $$PWD/web $$OUT_PWD/littlenavmap.app/Contents/MacOS &&
  copydata.commands += cp -Rv $$PWD/customize $$OUT_PWD/littlenavmap.app/Contents/MacOS &&
  copydata.commands += cp -Rv $$PWD/magdec $$OUT_PWD/littlenavmap.app/Contents/MacOS &&
  copydata.commands += cp -Rv $$PWD/marble/data $$OUT_PWD/littlenavmap.app/Contents/MacOS &&
  copydata.commands += cp -vf $$PWD/*.qm $$OUT_PWD/littlenavmap.app/Contents/MacOS &&
  copydata.commands += cp -vf $$ATOOLS_INC_PATH/../*.qm $$OUT_PWD/littlenavmap.app/Contents/MacOS
}

# =====================================================================
# Deployment commands

# Linux specific deploy target
unix:!macx {
  DEPLOY_DIR=\"$$DEPLOY_BASE/$$TARGET_NAME\"
  DEPLOY_DIR_LIB=\"$$DEPLOY_BASE/$$TARGET_NAME/lib\"

  deploy.commands += rm -Rfv $$DEPLOY_DIR &&
  deploy.commands += mkdir -pv $$DEPLOY_DIR_LIB &&
  deploy.commands += mkdir -pv $$DEPLOY_DIR_LIB/iconengines &&
  deploy.commands += mkdir -pv $$DEPLOY_DIR_LIB/imageformats &&
  deploy.commands += mkdir -pv $$DEPLOY_DIR_LIB/platforms &&
  deploy.commands += mkdir -pv $$DEPLOY_DIR_LIB/platformthemes &&
  deploy.commands += mkdir -pv $$DEPLOY_DIR_LIB/printsupport &&
  deploy.commands += mkdir -pv $$DEPLOY_DIR_LIB/sqldrivers &&
  deploy.commands += cp -Rvf $$MARBLE_LIB_PATH/*.so* $$DEPLOY_DIR_LIB &&
  deploy.commands += patchelf --set-rpath \'\$\$ORIGIN/.\' $$DEPLOY_DIR_LIB/libmarblewidget-qt5.so* &&
  deploy.commands += patchelf --set-rpath \'\$\$ORIGIN/.\' $$DEPLOY_DIR_LIB/libastro.so* &&
  deploy.commands += cp -Rvf $$OUT_PWD/plugins $$DEPLOY_DIR &&
  deploy.commands += cp -Rvf $$OUT_PWD/data $$DEPLOY_DIR &&
  deploy.commands += cp -Rvf $$OUT_PWD/help $$DEPLOY_DIR &&
  deploy.commands += cp -Rvf $$OUT_PWD/web $$DEPLOY_DIR &&
  deploy.commands += cp -Rvf $$OUT_PWD/customize $$DEPLOY_DIR &&
  deploy.commands += cp -Rvf $$OUT_PWD/translations $$DEPLOY_DIR &&
  deploy.commands += cp -Rvf $$OUT_PWD/magdec $$DEPLOY_DIR &&
  deploy.commands += cp -Rvf $$OUT_PWD/littlenavmap $$DEPLOY_DIR &&
  deploy.commands += cp -vfa $$[QT_INSTALL_TRANSLATIONS]/qt_??.qm  $$DEPLOY_DIR/translations &&
  deploy.commands += cp -vfa $$[QT_INSTALL_TRANSLATIONS]/qt_??_??.qm  $$DEPLOY_DIR/translations &&
  deploy.commands += cp -vfa $$[QT_INSTALL_TRANSLATIONS]/qtbase*.qm  $$DEPLOY_DIR/translations &&
  exists($$DATABASE_BASE) : deploy.commands += cp -Rvf $$DATABASE_BASE $$DEPLOY_DIR &&
  exists($$HELP_BASE) : deploy.commands += cp -Rvf $$HELP_BASE/* $$DEPLOY_DIR/help &&
  deploy.commands += cp -vf $$PWD/desktop/qt.conf $$DEPLOY_DIR &&
  deploy.commands += cp -vf $$PWD/CHANGELOG.txt $$DEPLOY_DIR &&
  deploy.commands += cp -vf $$PWD/README.txt $$DEPLOY_DIR &&
  deploy.commands += cp -vf $$PWD/LICENSE.txt $$DEPLOY_DIR &&
  deploy.commands += cp -vf $$PWD/resources/icons/littlenavmap.svg $$DEPLOY_DIR &&
  deploy.commands += cp -vf \"$$PWD/desktop/Little Navmap.desktop\" $$DEPLOY_DIR &&
  deploy.commands += cp -vfa $$[QT_INSTALL_PLUGINS]/iconengines/libqsvgicon.so*  $$DEPLOY_DIR_LIB/iconengines &&
  deploy.commands += cp -vfa $$[QT_INSTALL_PLUGINS]/imageformats/libqgif.so*  $$DEPLOY_DIR_LIB/imageformats &&
  deploy.commands += cp -vfa $$[QT_INSTALL_PLUGINS]/imageformats/libqjpeg.so*  $$DEPLOY_DIR_LIB/imageformats &&
  deploy.commands += cp -vfa $$[QT_INSTALL_PLUGINS]/imageformats/libqsvg.so*  $$DEPLOY_DIR_LIB/imageformats &&
  deploy.commands += cp -vfa $$[QT_INSTALL_PLUGINS]/imageformats/libqwbmp.so*  $$DEPLOY_DIR_LIB/imageformats &&
  deploy.commands += cp -vfa $$[QT_INSTALL_PLUGINS]/imageformats/libqwebp.so*  $$DEPLOY_DIR_LIB/imageformats &&
  deploy.commands += cp -vfa $$[QT_INSTALL_PLUGINS]/platforms/libqeglfs.so*  $$DEPLOY_DIR_LIB/platforms &&
  deploy.commands += cp -vfa $$[QT_INSTALL_PLUGINS]/platforms/libqlinuxfb.so*  $$DEPLOY_DIR_LIB/platforms &&
  deploy.commands += cp -vfa $$[QT_INSTALL_PLUGINS]/platforms/libqminimal.so*  $$DEPLOY_DIR_LIB/platforms &&
  deploy.commands += cp -vfa $$[QT_INSTALL_PLUGINS]/platforms/libqminimalegl.so*  $$DEPLOY_DIR_LIB/platforms &&
  deploy.commands += cp -vfa $$[QT_INSTALL_PLUGINS]/platforms/libqoffscreen.so*  $$DEPLOY_DIR_LIB/platforms &&
  deploy.commands += cp -vfa $$[QT_INSTALL_PLUGINS]/platforms/libqxcb.so*  $$DEPLOY_DIR_LIB/platforms &&
  deploy.commands += cp -vfa $$[QT_INSTALL_PLUGINS]/platformthemes/libqgtk*.so*  $$DEPLOY_DIR_LIB/platformthemes &&
  deploy.commands += cp -vfa $$[QT_INSTALL_PLUGINS]/printsupport/libcupsprintersupport.so*  $$DEPLOY_DIR_LIB/printsupport &&
  deploy.commands += cp -vfa $$[QT_INSTALL_PLUGINS]/sqldrivers/libqsqlite.so*  $$DEPLOY_DIR_LIB/sqldrivers &&
  deploy.commands += cp -vfa $$OPENSSL_PATH/libssl.so.1.0.0 $$DEPLOY_DIR_LIB &&
  deploy.commands += cp -vfa $$OPENSSL_PATH/libcrypto.so.1.0.0 $$DEPLOY_DIR_LIB &&
  deploy.commands += cp -vfa $$[QT_INSTALL_LIBS]/libicudata.so*  $$DEPLOY_DIR_LIB &&
  deploy.commands += cp -vfa $$[QT_INSTALL_LIBS]/libicui18n.so*  $$DEPLOY_DIR_LIB &&
  deploy.commands += cp -vfa $$[QT_INSTALL_LIBS]/libicuuc.so*  $$DEPLOY_DIR_LIB &&
  deploy.commands += cp -vfa $$[QT_INSTALL_LIBS]/libQt5Concurrent.so*  $$DEPLOY_DIR_LIB &&
  deploy.commands += cp -vfa $$[QT_INSTALL_LIBS]/libQt5Core.so*  $$DEPLOY_DIR_LIB &&
  deploy.commands += cp -vfa $$[QT_INSTALL_LIBS]/libQt5DBus.so*  $$DEPLOY_DIR_LIB &&
  deploy.commands += cp -vfa $$[QT_INSTALL_LIBS]/libQt5Gui.so*  $$DEPLOY_DIR_LIB &&
  deploy.commands += cp -vfa $$[QT_INSTALL_LIBS]/libQt5Network.so*  $$DEPLOY_DIR_LIB &&
  deploy.commands += cp -vfa $$[QT_INSTALL_LIBS]/libQt5PrintSupport.so*  $$DEPLOY_DIR_LIB &&
  deploy.commands += cp -vfa $$[QT_INSTALL_LIBS]/libQt5Qml.so*  $$DEPLOY_DIR_LIB &&
  deploy.commands += cp -vfa $$[QT_INSTALL_LIBS]/libQt5Quick.so*  $$DEPLOY_DIR_LIB &&
  deploy.commands += cp -vfa $$[QT_INSTALL_LIBS]/libQt5Script.so*  $$DEPLOY_DIR_LIB &&
  deploy.commands += cp -vfa $$[QT_INSTALL_LIBS]/libQt5Sql.so*  $$DEPLOY_DIR_LIB &&
  deploy.commands += cp -vfa $$[QT_INSTALL_LIBS]/libQt5Svg.so*  $$DEPLOY_DIR_LIB &&
  deploy.commands += cp -vfa $$[QT_INSTALL_LIBS]/libQt5Widgets.so*  $$DEPLOY_DIR_LIB &&
  deploy.commands += cp -vfa $$[QT_INSTALL_LIBS]/libQt5X11Extras.so*  $$DEPLOY_DIR_LIB &&
  deploy.commands += cp -vfa $$[QT_INSTALL_LIBS]/libQt5XcbQpa.so*  $$DEPLOY_DIR_LIB &&
  deploy.commands += cp -vfa $$[QT_INSTALL_LIBS]/libQt5Xml.so* $$DEPLOY_DIR_LIB
}

# Mac specific deploy target
macx {

INSTALL_MARBLE_DYLIB_CMD=install_name_tool \
         -change  $$INSTALL_MARBLE_DYLIB \
          @executable_path/../Frameworks/libmarblewidget-qt5.25.dylib $$OUT_PWD/littlenavmap.app/Contents/PlugIns

#  INSTALL_MARBLE_DYLIB_CMD=install_name_tool \
#         -change $$clean_path($$MARBLE_BUILD_PATH/src/lib/marble/libmarblewidget-qt5.25.dylib) \
#          @executable_path/../Frameworks/libmarblewidget-qt5.25.dylib $$OUT_PWD/littlenavmap.app/Contents/PlugIns

  DEPLOY_APP=\"$$PWD/../deploy/Little Navmap.app\"
  DEPLOY_DIR=\"$$PWD/../deploy\"

message(INSTALL_MARBLE_DYLIB_CMD: $$INSTALL_MARBLE_DYLIB_CMD)

  deploy.commands = rm -Rfv $$DEPLOY_APP &&
  deploy.commands += mkdir -p $$OUT_PWD/littlenavmap.app/Contents/PlugIns &&
  exists($$DATABASE_BASE) : deploy.commands += cp -Rvf $$DATABASE_BASE $$OUT_PWD/littlenavmap.app/Contents/MacOS &&
  exists($$HELP_BASE) : deploy.commands += cp -Rvf $$HELP_BASE/* $$OUT_PWD/littlenavmap.app/Contents/MacOS/help &&
  deploy.commands += cp -Rvf \
    $$MARBLE_LIB_PATH/plugins/libCachePlugin.so \
    $$MARBLE_LIB_PATH/plugins/libCompassFloatItem.so \
    $$MARBLE_LIB_PATH/plugins/libGraticulePlugin.so \
    $$MARBLE_LIB_PATH/plugins/libKmlPlugin.so \
    $$MARBLE_LIB_PATH/plugins/libLatLonPlugin.so \
    $$MARBLE_LIB_PATH/plugins/libLicense.so \
    $$MARBLE_LIB_PATH/plugins/libMapScaleFloatItem.so \
    $$MARBLE_LIB_PATH/plugins/libNavigationFloatItem.so \
    $$MARBLE_LIB_PATH/plugins/libOsmPlugin.so \
    $$MARBLE_LIB_PATH/plugins/libOverviewMap.so \
    $$MARBLE_LIB_PATH/plugins/libPn2Plugin.so \
    $$MARBLE_LIB_PATH/plugins/libPntPlugin.so \
    $$OUT_PWD/littlenavmap.app/Contents/PlugIns &&
  deploy.commands +=  $$INSTALL_MARBLE_DYLIB_CMD/libCachePlugin.so &&
  deploy.commands +=  $$INSTALL_MARBLE_DYLIB_CMD/libCachePlugin.so &&
  deploy.commands +=  $$INSTALL_MARBLE_DYLIB_CMD/libCompassFloatItem.so &&
  deploy.commands +=  $$INSTALL_MARBLE_DYLIB_CMD/libGraticulePlugin.so &&
  deploy.commands +=  $$INSTALL_MARBLE_DYLIB_CMD/libKmlPlugin.so &&
  deploy.commands +=  $$INSTALL_MARBLE_DYLIB_CMD/libLatLonPlugin.so &&
  deploy.commands +=  $$INSTALL_MARBLE_DYLIB_CMD/libLicense.so &&
  deploy.commands +=  $$INSTALL_MARBLE_DYLIB_CMD/libMapScaleFloatItem.so &&
  deploy.commands +=  $$INSTALL_MARBLE_DYLIB_CMD/libNavigationFloatItem.so &&
  deploy.commands +=  $$INSTALL_MARBLE_DYLIB_CMD/libOsmPlugin.so &&
  deploy.commands +=  $$INSTALL_MARBLE_DYLIB_CMD/libOverviewMap.so &&
  deploy.commands +=  $$INSTALL_MARBLE_DYLIB_CMD/libPn2Plugin.so &&
  deploy.commands +=  $$INSTALL_MARBLE_DYLIB_CMD/libPntPlugin.so &&
  deploy.commands += macdeployqt littlenavmap.app -always-overwrite &&
  deploy.commands += cp -rfv $$OUT_PWD/littlenavmap.app $$DEPLOY_APP &&
  deploy.commands += cp -fv $$[QT_INSTALL_TRANSLATIONS]/qt_??.qm  $$DEPLOY_APP/Contents/MacOS &&
  deploy.commands += cp -fv $$[QT_INSTALL_TRANSLATIONS]/qt_??_??.qm  $$DEPLOY_APP/Contents/MacOS &&
  deploy.commands += cp -fv $$[QT_INSTALL_TRANSLATIONS]/qtbase*.qm  $$DEPLOY_APP/Contents/MacOS &&
  deploy.commands += cp -fv $$PWD/LICENSE.txt $$DEPLOY_DIR &&
  deploy.commands += cp -fv $$PWD/README.txt $$DEPLOY_DIR/README-LittleNavmap.txt &&
  deploy.commands += cp -fv $$PWD/CHANGELOG.txt $$DEPLOY_DIR/CHANGELOG-LittleNavmap.txt


# -verbose=3
}

# Windows specific deploy target
win32 {
  defineReplace(p){return ($$shell_quote($$shell_path($$1)))}
  RC_ICONS = resources/icons/littlenavmap.ico

  CONFIG(debug, debug|release) : DLL_SUFFIX=d
  CONFIG(release, debug|release) : DLL_SUFFIX=

  deploy.commands = rmdir /s /q $$p($$DEPLOY_BASE/$$TARGET_NAME) &
  deploy.commands += mkdir $$p($$DEPLOY_BASE/$$TARGET_NAME/translations) &&
  deploy.commands += mkdir $$p($$DEPLOY_BASE/$$TARGET_NAME/plugins) &&
  deploy.commands += xcopy $$p($$MARBLE_LIB_PATH/../plugins/libCachePlugin$${DLL_SUFFIX}.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME/plugins) &&
  deploy.commands += xcopy $$p($$MARBLE_LIB_PATH/../plugins/libCompassFloatItem$${DLL_SUFFIX}.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME/plugins) &&
  deploy.commands += xcopy $$p($$MARBLE_LIB_PATH/../plugins/libGraticulePlugin$${DLL_SUFFIX}.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME/plugins) &&
  deploy.commands += xcopy $$p($$MARBLE_LIB_PATH/../plugins/libKmlPlugin$${DLL_SUFFIX}.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME/plugins) &&
  deploy.commands += xcopy $$p($$MARBLE_LIB_PATH/../plugins/libLatLonPlugin$${DLL_SUFFIX}.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME/plugins) &&
  deploy.commands += xcopy $$p($$MARBLE_LIB_PATH/../plugins/libLicense$${DLL_SUFFIX}.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME/plugins) &&
  deploy.commands += xcopy $$p($$MARBLE_LIB_PATH/../plugins/libMapScaleFloatItem$${DLL_SUFFIX}.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME/plugins) &&
  deploy.commands += xcopy $$p($$MARBLE_LIB_PATH/../plugins/libNavigationFloatItem$${DLL_SUFFIX}.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME/plugins) &&
  deploy.commands += xcopy $$p($$MARBLE_LIB_PATH/../plugins/libOsmPlugin$${DLL_SUFFIX}.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME/plugins) &&
  deploy.commands += xcopy $$p($$MARBLE_LIB_PATH/../plugins/libOverviewMap$${DLL_SUFFIX}.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME/plugins) &&
  deploy.commands += xcopy $$p($$MARBLE_LIB_PATH/../plugins/libPn2Plugin$${DLL_SUFFIX}.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME/plugins) &&
  deploy.commands += xcopy $$p($$MARBLE_LIB_PATH/../plugins/libPntPlugin$${DLL_SUFFIX}.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME/plugins) &&
  deploy.commands += xcopy $$p($$OUT_PWD/littlenavmap.exe) $$p($$DEPLOY_BASE/$$TARGET_NAME) &&
  deploy.commands += xcopy $$p($$PWD/CHANGELOG.txt) $$p($$DEPLOY_BASE/$$TARGET_NAME) &&
  deploy.commands += xcopy $$p($$PWD/README.txt) $$p($$DEPLOY_BASE/$$TARGET_NAME) &&
  deploy.commands += xcopy $$p($$PWD/LICENSE.txt) $$p($$DEPLOY_BASE/$$TARGET_NAME) &&
  deploy.commands += xcopy $$p($$PWD/*.qm) $$p($$DEPLOY_BASE/$$TARGET_NAME/translations) &&
  deploy.commands += xcopy $$p($$ATOOLS_INC_PATH/../*.qm) $$p($$DEPLOY_BASE/$$TARGET_NAME/translations) &&
  exists($$DATABASE_BASE) : deploy.commands += xcopy /i /s /e /f /y $$p($$DATABASE_BASE) $$p($$DEPLOY_BASE/$$TARGET_NAME/little_navmap_db) &&
  exists($$HELP_BASE) : deploy.commands += xcopy /i /s /e /f /y $$p($$HELP_BASE) $$p($$DEPLOY_BASE/$$TARGET_NAME/help) &&
  deploy.commands += xcopy $$p($$PWD/littlenavmap.exe.simconnect) $$p($$DEPLOY_BASE/$$TARGET_NAME) &&
  deploy.commands += xcopy /i /s /e /f /y $$p($$PWD/help) $$p($$DEPLOY_BASE/$$TARGET_NAME/help) &&
  deploy.commands += xcopy /i /s /e /f /y $$p($$PWD/web) $$p($$DEPLOY_BASE/$$TARGET_NAME/web) &&
  deploy.commands += xcopy /i /s /e /f /y $$p($$PWD/customize) $$p($$DEPLOY_BASE/$$TARGET_NAME/customize) &&
  deploy.commands += xcopy /i /s /e /f /y $$p($$PWD/magdec) $$p($$DEPLOY_BASE/$$TARGET_NAME/magdec) &&
  deploy.commands += xcopy /i /s /e /f /y $$p($$PWD/etc) $$p($$DEPLOY_BASE/$$TARGET_NAME/etc) &&
  deploy.commands += xcopy /i /s /e /f /y $$p($$PWD/marble/data) $$p($$DEPLOY_BASE/$$TARGET_NAME/data) &&
  deploy.commands += xcopy $$p($$MARBLE_LIB_PATH/../libmarblewidget-qt5$${DLL_SUFFIX}.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME) &&
  deploy.commands += xcopy $$p($$MARBLE_LIB_PATH/../libastro$${DLL_SUFFIX}.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME) &&
  deploy.commands += xcopy $$p($$[QT_INSTALL_BINS]/libgcc*.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME) &&
  deploy.commands += xcopy $$p($$[QT_INSTALL_BINS]/libstdc*.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME) &&
  deploy.commands += xcopy $$p($$[QT_INSTALL_BINS]/libwinpthread*.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME) &&
  deploy.commands += xcopy $$p($$OPENSSL_PATH/bin/libeay32.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME) &&
  deploy.commands += xcopy $$p($$OPENSSL_PATH/bin/ssleay32.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME) &&
  deploy.commands += xcopy $$p($$OPENSSL_PATH/libssl32.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME) &&
  deploy.commands += xcopy $$p($$[QT_INSTALL_BINS]/Qt5DBus$${DLL_SUFFIX}.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME) &&
  deploy.commands += xcopy $$p($$[QT_INSTALL_BINS]/Qt5Network$${DLL_SUFFIX}.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME) &&
  deploy.commands += xcopy $$p($$[QT_INSTALL_BINS]/Qt5PrintSupport$${DLL_SUFFIX}.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME) &&
  deploy.commands += xcopy $$p($$[QT_INSTALL_BINS]/Qt5Qml$${DLL_SUFFIX}.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME) &&
  deploy.commands += xcopy $$p($$[QT_INSTALL_BINS]/Qt5Sql$${DLL_SUFFIX}.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME) &&
  deploy.commands += xcopy $$p($$[QT_INSTALL_BINS]/Qt5Quick$${DLL_SUFFIX}.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME) &&
  deploy.commands += xcopy $$p($$[QT_INSTALL_BINS]/Qt5Script$${DLL_SUFFIX}.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME) &&
  deploy.commands += xcopy $$p($$[QT_INSTALL_BINS]/Qt5Multimedia$${DLL_SUFFIX}.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME) &&
  deploy.commands += xcopy $$p($$[QT_INSTALL_BINS]/Qt5OpenGL$${DLL_SUFFIX}.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME) &&
  deploy.commands += xcopy $$p($$[QT_INSTALL_BINS]/Qt5MultimediaWidgets$${DLL_SUFFIX}.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME) &&
  deploy.commands += xcopy $$p($$[QT_INSTALL_BINS]/Qt5Xml$${DLL_SUFFIX}.dll) $$p($$DEPLOY_BASE/$$TARGET_NAME) &&
  deploy.commands += $$p($$[QT_INSTALL_BINS]/windeployqt) $$WINDEPLOY_FLAGS $$p($$DEPLOY_BASE/$$TARGET_NAME)
}

# =====================================================================
# Additional targets

# Need to copy data when compiling
all.depends = copydata

# Deploy needs compiling before
deploy.depends = all

QMAKE_EXTRA_TARGETS += deploy copydata all

