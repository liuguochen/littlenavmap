/*****************************************************************************
* Copyright 2015-2017 Alexander Barthel albar965@mailbox.org
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

#include "navapp.h"

#include "query/infoquery.h"
#include "query/procedurequery.h"
#include "connect/connectclient.h"
#include "query/mapquery.h"
#include "query/airportquery.h"
#include "db/databasemanager.h"
#include "fs/db/databasemeta.h"
#include "mapgui/mapwidget.h"
#include "gui/mainwindow.h"
#include "route/routecontroller.h"
#include "common/elevationprovider.h"
#include "fs/common/magdecreader.h"
#include "common/updatehandler.h"

#include "ui_mainwindow.h"

#include <marble/MarbleModel.h>

#include <QIcon>
#include <QSplashScreen>

AirportQuery *NavApp::airportQuery = nullptr;
AirportQuery *NavApp::airportQueryNav = nullptr;
MapQuery *NavApp::mapQuery = nullptr;
InfoQuery *NavApp::infoQuery = nullptr;
ProcedureQuery *NavApp::procedureQuery = nullptr;

ConnectClient *NavApp::connectClient = nullptr;
DatabaseManager *NavApp::databaseManager = nullptr;
MainWindow *NavApp::mainWindow = nullptr;
ElevationProvider *NavApp::elevationProvider = nullptr;
atools::fs::db::DatabaseMeta *NavApp::databaseMeta = nullptr;
atools::fs::db::DatabaseMeta *NavApp::databaseMetaNav = nullptr;
QSplashScreen *NavApp::splashScreen = nullptr;

atools::fs::common::MagDecReader *NavApp::magDecReader = nullptr;
UpdateHandler *NavApp::updateHandler = nullptr;

bool NavApp::shuttingDown = false;

NavApp::NavApp(int& argc, char **argv, int flags)
  : atools::gui::Application(argc, argv, flags)
{
  setWindowIcon(QIcon(":/littlenavmap/resources/icons/littlenavmap.svg"));
  setApplicationName("Little Navmap");
  setOrganizationName("ABarthel");
  setOrganizationDomain("abarthel.org");

  // VERSION_NUMBER
  setApplicationVersion("1.7.0.develop");
}

NavApp::~NavApp()
{
}

void NavApp::init(MainWindow *mainWindowParam)
{
  qDebug() << Q_FUNC_INFO;

  NavApp::mainWindow = mainWindowParam;
  databaseManager = new DatabaseManager(mainWindow);
  databaseManager->openDatabase();

  databaseMeta = new atools::fs::db::DatabaseMeta(getDatabaseSim());
  databaseMetaNav = new atools::fs::db::DatabaseMeta(getDatabaseNav());

  magDecReader = new atools::fs::common::MagDecReader();
  magDecReader->readFromTable(*databaseManager->getDatabaseSim());

  mapQuery = new MapQuery(mainWindow, databaseManager->getDatabaseSim(), databaseManager->getDatabaseNav());
  mapQuery->initQueries();

  airportQuery = new AirportQuery(mainWindow, databaseManager->getDatabaseSim(), false /* nav */);
  airportQuery->initQueries();

  airportQueryNav = new AirportQuery(mainWindow, databaseManager->getDatabaseNav(), true /* nav */);
  airportQueryNav->initQueries();

  infoQuery = new InfoQuery(databaseManager->getDatabaseSim(), databaseManager->getDatabaseNav());
  infoQuery->initQueries();

  procedureQuery = new ProcedureQuery(databaseManager->getDatabaseNav());
  procedureQuery->initQueries();

  qDebug() << "MainWindow Creating ConnectClient";
  connectClient = new ConnectClient(mainWindow);

  qDebug() << "MainWindow Creating UpdateCheck";
  updateHandler = new UpdateHandler(mainWindow);
  // The check will be called on main window shown
}

void NavApp::initElevationProvider()
{
  elevationProvider = new ElevationProvider(mainWindow, mainWindow->getElevationModel());
}

void NavApp::deInit()
{
  qDebug() << Q_FUNC_INFO;

  qDebug() << Q_FUNC_INFO << "delete updateHandler";
  delete updateHandler;
  updateHandler = nullptr;

  qDebug() << Q_FUNC_INFO << "delete connectClient";
  delete connectClient;
  connectClient = nullptr;

  qDebug() << Q_FUNC_INFO << "delete elevationProvider";
  delete elevationProvider;
  elevationProvider = nullptr;

  qDebug() << Q_FUNC_INFO << "delete airportQuery";
  delete airportQuery;
  airportQuery = nullptr;

  qDebug() << Q_FUNC_INFO << "delete airportQueryNav";
  delete airportQueryNav;
  airportQueryNav = nullptr;

  qDebug() << Q_FUNC_INFO << "delete mapQuery";
  delete mapQuery;
  mapQuery = nullptr;

  qDebug() << Q_FUNC_INFO << "delete infoQuery";
  delete infoQuery;
  infoQuery = nullptr;

  qDebug() << Q_FUNC_INFO << "delete approachQuery";
  delete procedureQuery;
  procedureQuery = nullptr;

  qDebug() << Q_FUNC_INFO << "delete databaseManager";
  delete databaseManager;
  databaseManager = nullptr;

  qDebug() << Q_FUNC_INFO << "delete databaseMeta";
  delete databaseMeta;
  databaseMeta = nullptr;

  qDebug() << Q_FUNC_INFO << "delete databaseMetaNav";
  delete databaseMetaNav;
  databaseMetaNav = nullptr;

  qDebug() << Q_FUNC_INFO << "delete magDecReader";
  delete magDecReader;
  magDecReader = nullptr;

  qDebug() << Q_FUNC_INFO << "delete splashScreen";
  delete splashScreen;
  splashScreen = nullptr;
}

void NavApp::checkForUpdates(int channelOpts, bool manuallyTriggered)
{
  updateHandler->checkForUpdates(static_cast<opts::UpdateChannels>(channelOpts), manuallyTriggered);
}

void NavApp::optionsChanged()
{
  qDebug() << Q_FUNC_INFO;
}

void NavApp::preDatabaseLoad()
{
  qDebug() << Q_FUNC_INFO;

  infoQuery->deInitQueries();
  airportQuery->deInitQueries();
  airportQueryNav->deInitQueries();
  mapQuery->deInitQueries();
  procedureQuery->deInitQueries();

  delete databaseMeta;
  databaseMeta = nullptr;

  delete databaseMetaNav;
  databaseMetaNav = nullptr;
}

void NavApp::postDatabaseLoad()
{
  qDebug() << Q_FUNC_INFO;

  databaseMeta = new atools::fs::db::DatabaseMeta(getDatabaseSim());
  databaseMetaNav = new atools::fs::db::DatabaseMeta(getDatabaseNav());

  magDecReader->readFromTable(*getDatabaseSim());
  airportQuery->initQueries();
  airportQueryNav->initQueries();
  mapQuery->initQueries();
  infoQuery->initQueries();
  procedureQuery->initQueries();
}

Ui::MainWindow *NavApp::getMainUi()
{
  return mainWindow->getUi();
}

bool NavApp::isConnected()
{
  return NavApp::getConnectClient()->isConnected();
}

AirportQuery *NavApp::getAirportQuerySim()
{
  return airportQuery;
}

AirportQuery *NavApp::getAirportQueryNav()
{
  return airportQueryNav;
}

MapQuery *NavApp::getMapQuery()
{
  return mapQuery;
}

InfoQuery *NavApp::getInfoQuery()
{
  return infoQuery;
}

ProcedureQuery *NavApp::getProcedureQuery()
{
  return procedureQuery;
}

const Route& NavApp::getRoute()
{
  return mainWindow->getRouteController()->getRoute();
}

float NavApp::getSpeedKts()
{
  return mainWindow->getRouteController()->getSpinBoxSpeedKts();
}

atools::fs::FsPaths::SimulatorType NavApp::getCurrentSimulatorDb()
{
  return getDatabaseManager()->getCurrentSimulator();
}

QString NavApp::getCurrentSimulatorFilesPath()
{
  return atools::fs::FsPaths::getFilesPath(getCurrentSimulatorDb());
}

QString NavApp::getCurrentSimulatorBasePath()
{
  return databaseManager->getCurrentSimulatorBasePath();
}

QString NavApp::getSimulatorBasePath(atools::fs::FsPaths::SimulatorType type)
{
  return databaseManager->getSimulatorBasePath(type);
}

QString NavApp::getCurrentSimulatorShortName()
{
  return atools::fs::FsPaths::typeToShortName(getCurrentSimulatorDb());
}

bool NavApp::hasSidStarInDatabase()
{
  return databaseMetaNav->hasSidStar();
}

bool NavApp::hasDataInDatabase()
{
  return databaseMeta->hasData();
}

atools::sql::SqlDatabase *NavApp::getDatabaseSim()
{
  return getDatabaseManager()->getDatabaseSim();
}

atools::sql::SqlDatabase *NavApp::getDatabaseNav()
{
  return getDatabaseManager()->getDatabaseNav();
}

ElevationProvider *NavApp::getElevationProvider()
{
  return elevationProvider;
}

WeatherReporter *NavApp::getWeatherReporter()
{
  return mainWindow->getWeatherReporter();
}

void NavApp::updateWindowTitle()
{
  mainWindow->updateWindowTitle();
}

void NavApp::setStatusMessage(const QString& message)
{
  mainWindow->setStatusMessage(message);
}

QWidget *NavApp::getQMainWidget()
{
  return mainWindow;
}

QMainWindow *NavApp::getQMainWindow()
{
  return mainWindow;
}

MainWindow *NavApp::getMainWindow()
{
  return mainWindow;
}

MapWidget *NavApp::getMapWidget()
{
  return mainWindow->getMapWidget();
}

RouteController *NavApp::getRouteController()
{
  return mainWindow->getRouteController();
}

DatabaseManager *NavApp::getDatabaseManager()
{
  return databaseManager;
}

ConnectClient *NavApp::getConnectClient()
{
  return connectClient;
}

QString NavApp::getDatabaseAiracCycle()
{
  return databaseMeta->getAiracCycle();
}

QString NavApp::getDatabaseAiracCycleNav()
{
  return databaseMetaNav->getAiracCycle();
}

bool NavApp::hasDatabaseAirspaces()
{
  return databaseMetaNav->hasAirspaces();
}

const atools::fs::db::DatabaseMeta *NavApp::getDatabaseMetaSim()
{
  return databaseMeta;
}

const atools::fs::db::DatabaseMeta *NavApp::getDatabaseMetaNav()
{
  return databaseMetaNav;
}

const AircraftTrack& NavApp::getAircraftTrack()
{
  return getMapWidget()->getAircraftTrack();
}

map::MapObjectTypes NavApp::getShownMapFeatures()
{
  return mainWindow->getMapWidget()->getShownMapFeatures();
}

map::MapAirspaceFilter NavApp::getShownMapAirspaces()
{
  return mainWindow->getMapWidget()->getShownAirspaces();
}

void NavApp::deleteSplashScreen()
{
  qDebug() << Q_FUNC_INFO;

  if(splashScreen != nullptr)
    splashScreen->close();
}

bool NavApp::isShuttingDown()
{
  return shuttingDown;
}

void NavApp::setShuttingDown(bool value)
{
  qDebug() << Q_FUNC_INFO << value;

  shuttingDown = value;
}

float NavApp::getMagVar(const atools::geo::Pos& pos, float defaultValue)
{
  if(magDecReader != nullptr && magDecReader->isValid())
    return magDecReader->getMagVar(pos);
  else
    return defaultValue;
}

UpdateHandler *NavApp::getUpdateHandler()
{
  return updateHandler;
}

void NavApp::initSplashScreen()
{
  qDebug() << Q_FUNC_INFO;

  QPixmap pixmap(":/littlenavmap/resources/icons/splash.png");
  splashScreen = new QSplashScreen(pixmap);
  splashScreen->show();

  processEvents();

  splashScreen->showMessage(QObject::tr("Version %5 (revision %6)").
                            arg(Application::applicationVersion()).arg(GIT_REVISION),
                            Qt::AlignRight | Qt::AlignBottom, Qt::white);

  processEvents(QEventLoop::ExcludeUserInputEvents);
}

void NavApp::finishSplashScreen()
{
  qDebug() << Q_FUNC_INFO;

  if(splashScreen != nullptr)
    splashScreen->finish(mainWindow);
}
