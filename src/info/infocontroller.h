/*****************************************************************************
* Copyright 2015-2019 Alexander Barthel alex@littlenavmap.org
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*****************************************************************************/

#ifndef LITTLENAVMAP_INFOCONTROLLER_H
#define LITTLENAVMAP_INFOCONTROLLER_H

#include "fs/sc/simconnectdata.h"
#include "common/maptypes.h"

#include <QObject>

class MainWindow;
class MapQuery;
class AirportQuery;
class AirspaceQuery;
class InfoQuery;
class HtmlInfoBuilder;
class QTextEdit;

namespace atools {
namespace util {
class HtmlBuilder;
}
}

/*
 * Takes care of the information and simulator aircraft dock windows and tabs
 */
class InfoController :
  public QObject
{
  Q_OBJECT

public:
  InfoController(MainWindow *parent);
  virtual ~InfoController();

  /* Populates all tabs in the information dock with the given results. Only one airport is shown
   * but multiple navaids can be shown in the tab.
   *  Raises all related windows and tabs and scrolls to top. */
  void showInformation(map::MapSearchResult result, map::MapObjectTypes preferredType);

  /* Update the currently shown airport information if weather data or connection status has changed.
   * Does not raise windows and does not scroll to top. */
  void updateAirport();
  void updateAirportWeather();

  /* Updates aircraft progress only. */
  void updateProgress();

  /* Update all and do not raise or scroll windows */
  void updateAllInformation();

  /* Update all and do not raise or scroll windows */
  void onlineClientAndAtcUpdated();

  /* Updates all online related information and does not raise windows */
  void onlineNetworkChanged();

  /* Save ids of the objects shown in the tabs to content can be restored on startup */
  void saveState();
  void restoreState();

  /* Clear all panels and result set */
  void preDatabaseLoad();
  void postDatabaseLoad();

  /* Update aircraft and aircraft progress tab */
  void simDataChanged(atools::fs::sc::SimConnectData data);
  void connectedToSimulator();
  void disconnectedFromSimulator();

  /* Program options have changed */
  void optionsChanged();

  /* Get airport information as HTML in the string list. Order is main, runway, com, procedure and weather.
   * List is empty if airport does not exist. Uses own white background color for tables. */
  QStringList getAirportTextFull(const QString& ident) const;

signals:
  /* Emitted when the user clicks on the "Map" link in the text browsers */
  void showPos(const atools::geo::Pos& pos, float zoom, bool doubleClick);
  void showRect(const atools::geo::Rect& rect, bool doubleClick);

private:
  /* Do not update aircraft progress more than every 0.5 seconds */
  static Q_DECL_CONSTEXPR int MIN_SIM_UPDATE_TIME_MS = 500;

  /* Bearing update in information window time limit */
  static Q_DECL_CONSTEXPR int MIN_SIM_UPDATE_BEARING_TIME_MS = 1000;

  void updateAirportInternal(bool newAirport, bool bearingChange, bool scrollToTop, bool forceWeatherUpdate);
  bool updateNavaidInternal(const map::MapSearchResult& result, bool bearingChanged, bool scrollToTop);

  void updateTextEditFontSizes();
  void setTextEditFontSize(QTextEdit *textEdit, float origSize, int percent);
  void anchorClicked(const QUrl& url);
  void clearInfoTextBrowsers();
  void showInformationInternal(map::MapSearchResult result, map::MapObjectTypes preferredType,
                               bool showWindows, bool scrollToTop);
  void updateAiAirports(const atools::fs::sc::SimConnectData& data);
  void updateUserAircraftText();
  void updateAircraftProgressText();
  void updateAiAircraftText();
  void updateAircraftInfo();

  /* QTabWidget::currentChanged - update content when visible */
  void currentAircraftTabChanged(int index);
  void currentInfoTabChanged(int index);

  /* QDockWidget::visibilityChanged - update when shown */
  void visibilityChangedAircraft(bool visible);
  void visibilityChangedInfo(bool visible);

  bool databaseLoadStatus = false;
  atools::fs::sc::SimConnectData lastSimData;
  qint64 lastSimUpdate = 0;
  qint64 lastSimBearingUpdate = 0;

  /* Airport and navaids that are currently shown in the tabs */
  map::MapSearchResult currentSearchResult;

  MainWindow *mainWindow = nullptr;
  MapQuery *mapQuery = nullptr;
  AirspaceQuery *airspaceQuery = nullptr;
  AirspaceQuery *airspaceQueryOnline = nullptr;
  AirportQuery *airportQuery = nullptr;
  HtmlInfoBuilder *infoBuilder = nullptr;

  float simInfoFontPtSize = 10.f, infoFontPtSize = 10.f;
  bool lessAircraftProgress = false;
};

#endif // LITTLENAVMAP_INFOCONTROLLER_H
