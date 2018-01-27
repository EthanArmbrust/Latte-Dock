/*
*  Copyright 2016  Smith AR <audoban@openmailbox.org>
*                  Michail Vourlakos <mvourlakos@gmail.com>
*
*  This file is part of Latte-Dock
*
*  Latte-Dock is free software; you can redistribute it and/or
*  modify it under the terms of the GNU General Public License as
*  published by the Free Software Foundation; either version 2 of
*  the License, or (at your option) any later version.
*
*  Latte-Dock is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  GNU General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "dockconfigview.h"
#include "dockview.h"
#include "dockcorona.h"
#include "panelshadows_p.h"
#include "abstractwindowinterface.h"
#include "../liblattedock/dock.h"

#include <QFontMetrics>
#include <QQuickItem>
#include <QQmlContext>
#include <QQmlEngine>
#include <QScreen>

#include <KLocalizedContext>
#include <KDeclarative/KDeclarative>

#include <Plasma/Package>

#include <KWayland/Client/plasmashell.h>
#include <KWayland/Client/surface.h>

#include <KWindowSystem>

namespace Latte {

DockConfigView::DockConfigView(Plasma::Containment *containment, DockView *dockView, ConfigViewType type, QWindow *parent)
    : PlasmaQuick::ConfigView(containment, parent),
      m_configType(type),
      m_dockView(dockView)
{
    setupWaylandIntegration();

    setScreen(m_dockView->screen());

    if (containment) {
        setIcon(qGuiApp->windowIcon());
    }

    m_screenSyncTimer.setSingleShot(true);
    m_screenSyncTimer.setInterval(100);

    connections << connect(&m_screenSyncTimer, &QTimer::timeout, this, [this]() {
        setScreen(m_dockView->screen());
        setFlags(wFlags());
        syncGeometry();
        syncSlideEffect();
    });
    connections << connect(dockView->visibility(), &VisibilityManager::modeChanged, this, &DockConfigView::syncGeometry);
    connections << connect(containment, &Plasma::Containment::immutabilityChanged, this, &DockConfigView::immutabilityChanged);

    m_thicknessSyncTimer.setSingleShot(true);
    m_thicknessSyncTimer.setInterval(200);
    connections << connect(&m_thicknessSyncTimer, &QTimer::timeout, this, [this]() {
        syncGeometry();
    });

    connections << connect(dockView, &DockView::normalThicknessChanged, [&]() {
        m_thicknessSyncTimer.start();
    });

    auto *dockCorona = qobject_cast<DockCorona *>(m_dockView->corona());

    if (dockCorona && m_configType == PrimaryConfig) {
        connections << connect(dockCorona, SIGNAL(raiseDocksTemporaryChanged()), this, SIGNAL(raiseDocksTemporaryChanged()));
    }
}

DockConfigView::~DockConfigView()
{
    qDebug() << "DockConfigView deleting ...";

    foreach (auto var, connections) {
        QObject::disconnect(var);
    }

    if (m_shellSurface) {
        delete m_shellSurface;
        m_shellSurface = nullptr;
    }

}

void DockConfigView::init()
{
    qDebug() << "dock config view : initialization started...";

    setDefaultAlphaBuffer(true);
    setColor(Qt::transparent);
    PanelShadows::self()->addWindow(this);
    rootContext()->setContextProperty(QStringLiteral("dock"), m_dockView);
    rootContext()->setContextProperty(QStringLiteral("dockConfig"), this);
    auto *dockCorona = qobject_cast<DockCorona *>(m_dockView->corona());

    if (dockCorona) {
        rootContext()->setContextProperty(QStringLiteral("layoutManager"), dockCorona->layoutManager());
    }

    KDeclarative::KDeclarative kdeclarative;
    kdeclarative.setDeclarativeEngine(engine());
    kdeclarative.setTranslationDomain(QStringLiteral("latte-dock"));
    kdeclarative.setupBindings();

    QByteArray tempFilePath = m_configType == PrimaryConfig ? "lattedockconfigurationui" : "lattedocksecondaryconfigurationui";

    m_largeSpacing = QFontMetrics(QGuiApplication::font()).boundingRect(QStringLiteral("M")).height();

    updateEnabledBorders();

    auto source = QUrl::fromLocalFile(m_dockView->containment()->corona()->kPackage().filePath(tempFilePath));
    setSource(source);
    syncGeometry();
    syncSlideEffect();

    qDebug() << "dock config view : initialization ended...";
}

inline Qt::WindowFlags DockConfigView::wFlags() const
{
    return (flags() | Qt::FramelessWindowHint | Qt::WindowStaysOnTopHint) & ~Qt::WindowDoesNotAcceptFocus;
}

void DockConfigView::syncGeometry()
{
    if (!m_dockView->managedLayout() || !m_dockView->containment() || !rootObject())
        return;

    const auto location = m_dockView->containment()->location();
    const auto sGeometry = screen()->geometry();

    int clearThickness = m_dockView->normalThickness();

    int secondaryConfigSpacing = 2 * m_largeSpacing;

    QPoint position{0, 0};

    switch (m_dockView->containment()->formFactor()) {
        case Plasma::Types::Horizontal: {
            const QSize size(rootObject()->width(), rootObject()->height());
            setMaximumSize(size);
            setMinimumSize(size);
            resize(size);


            if (location == Plasma::Types::TopEdge) {
                if (m_configType == PrimaryConfig) {
                    position = {sGeometry.center().x() - size.width() / 2
                                , sGeometry.y() + clearThickness
                               };
                } else {
                    int yPos = m_dockView->y() + clearThickness;

                    position = {m_dockView->x() + secondaryConfigSpacing, yPos};
                }
            } else if (location == Plasma::Types::BottomEdge) {
                if (m_configType == PrimaryConfig) {
                    position = {sGeometry.center().x() - size.width() / 2
                                , sGeometry.y() + sGeometry.height() - clearThickness - size.height()
                               };
                } else {
                    int yPos;
                    yPos = sGeometry.y() + sGeometry.height() - clearThickness - size.height();

                    position = {m_dockView->x() + m_dockView->width() - secondaryConfigSpacing - size.width(), yPos};
                }
            }
        }
        break;

        case Plasma::Types::Vertical: {
            const QSize size(rootObject()->width(), rootObject()->height());
            setMaximumSize(size);
            setMinimumSize(size);
            resize(size);

            if (location == Plasma::Types::LeftEdge) {
                if (m_configType == PrimaryConfig) {
                    position = {sGeometry.x() + clearThickness
                                , sGeometry.center().y() - size.height() / 2
                               };
                } else {
                    position = {sGeometry.x() + clearThickness
                                , m_dockView->y() + secondaryConfigSpacing
                               };
                }

            } else if (location == Plasma::Types::RightEdge) {
                if (m_configType == PrimaryConfig) {
                    position = {sGeometry.x() + sGeometry.width() - clearThickness - size.width()
                                , sGeometry.center().y() - size.height() / 2
                               };
                } else {
                    position = {sGeometry.x() + sGeometry.width() - clearThickness - size.width()
                                , m_dockView->y() + secondaryConfigSpacing
                               };
                }
            }
        }
        break;

        default:
            qWarning() << "no sync geometry, wrong formFactor";
            break;
    }

    updateEnabledBorders();

    setPosition(position);

    if (m_shellSurface) {
        m_shellSurface->setPosition(position);
    }
}

void DockConfigView::syncSlideEffect()
{
    if (!m_dockView->containment())
        return;

    auto slideLocation = WindowSystem::Slide::None;

    switch (m_dockView->containment()->location()) {
        case Plasma::Types::TopEdge:
            slideLocation = WindowSystem::Slide::Top;
            break;

        case Plasma::Types::RightEdge:
            slideLocation = WindowSystem::Slide::Right;
            break;

        case Plasma::Types::BottomEdge:
            slideLocation = WindowSystem::Slide::Bottom;
            break;

        case Plasma::Types::LeftEdge:
            slideLocation = WindowSystem::Slide::Left;
            break;

        default:
            qDebug() << staticMetaObject.className() << "wrong location";
            break;
    }

    WindowSystem::self().slideWindow(*this, slideLocation);
}

void DockConfigView::setVisibleWindow(bool visible)
{
    if (visible) {
        setMask(QRect());
        PanelShadows::self()->addWindow(this, enabledBorders());
    } else {
        PanelShadows::self()->removeWindow(this);
        setMask(QRect(0, 0, 1, 1));
    }
}

void DockConfigView::showEvent(QShowEvent *ev)
{
    QQuickWindow::showEvent(ev);

    WindowSystem::self().setDockExtraFlags(*this);
    setFlags(wFlags());

    WindowSystem::self().enableBlurBehind(*this);

    syncGeometry();
    syncSlideEffect();

    if (m_dockView && m_dockView->containment())
        m_dockView->containment()->setUserConfiguring(true);

    m_screenSyncTimer.start();
    QTimer::singleShot(400, this, &DockConfigView::syncGeometry);

    emit showSignal();
}

void DockConfigView::hideEvent(QHideEvent *ev)
{
    if (!m_dockView) {
        QQuickWindow::hideEvent(ev);
        return;
    }

    if (m_dockView->containment())
        m_dockView->containment()->setUserConfiguring(false);

    QQuickWindow::hideEvent(ev);

    auto recreateDock = [&]() noexcept {
        auto *dockCorona = qobject_cast<DockCorona *>(m_dockView->corona());

        if (dockCorona) {
            dockCorona->recreateDock(m_dockView->containment());
        }
    };

    if (m_configType == PrimaryConfig) {
        const auto mode = m_dockView->visibility()->mode();
        const auto previousDockWinBehavior = (m_dockView->flags() & Qt::BypassWindowManagerHint) ? false : true;

        if (mode == Dock::AlwaysVisible || mode == Dock::WindowsGoBelow) {
            if (!previousDockWinBehavior) {
                recreateDock();
            }
        } else if (m_dockView->dockWinBehavior() != previousDockWinBehavior) {
            recreateDock();
        }
    }

    deleteLater();
}

void DockConfigView::focusOutEvent(QFocusEvent *ev)
{
    Q_UNUSED(ev);

    /*if (m_configType != PrimaryConfig) {
        return;
    }*/

    const auto *focusWindow = qGuiApp->focusWindow();

    if (focusWindow && focusWindow->flags().testFlag(Qt::Popup))
        return;

    if (!m_blockFocusLost && !m_dockView->settingsWindowsAreActive() && !(m_configType == SecondaryConfig && m_blockFocusLostOnStartup)) {
        hideConfigWindow();
    }

    if (m_blockFocusLostOnStartup) {
        m_blockFocusLostOnStartup = false;
    }
}

void DockConfigView::setupWaylandIntegration()
{
    if (m_shellSurface || !KWindowSystem::isPlatformWayland() || !m_dockView || !m_dockView->containment()) {
        // already setup
        return;
    }

    if (DockCorona *c = qobject_cast<DockCorona *>(m_dockView->containment()->corona())) {
        using namespace KWayland::Client;
        PlasmaShell *interface = c->waylandDockCoronaInterface();

        if (!interface) {
            return;
        }

        Surface *s = Surface::fromWindow(this);

        if (!s) {
            return;
        }

        qDebug() << "wayland dock window surface was created...";

        m_shellSurface = interface->createSurface(s, this);

        syncGeometry();
    }
}

bool DockConfigView::event(QEvent *e)
{
    if (e->type() == QEvent::PlatformSurface) {
        if (auto pe = dynamic_cast<QPlatformSurfaceEvent *>(e)) {
            switch (pe->surfaceEventType()) {
                case QPlatformSurfaceEvent::SurfaceCreated:

                    if (m_shellSurface) {
                        break;
                    }

                    setupWaylandIntegration();
                    break;

                case QPlatformSurfaceEvent::SurfaceAboutToBeDestroyed:
                    if (m_shellSurface) {
                        delete m_shellSurface;
                        m_shellSurface = nullptr;
                    }

                    PanelShadows::self()->removeWindow(this);
                    break;
            }
        }
    }

    return PlasmaQuick::ConfigView::event(e);
}


void DockConfigView::immutabilityChanged(Plasma::Types::ImmutabilityType type)
{
    if (type != Plasma::Types::Mutable && isVisible())
        hideConfigWindow();
}

bool DockConfigView::sticker() const
{
    return m_blockFocusLost;
}

void DockConfigView::setSticker(bool blockFocusLost)
{
    if (m_blockFocusLost == blockFocusLost)
        return;

    m_blockFocusLost = blockFocusLost;

    m_dockView->setConfigWindowsSticker(blockFocusLost);
}

void DockConfigView::addPanelSpacer()
{
    if (m_dockView && m_dockView->containment()) {
        m_dockView->containment()->createApplet(QStringLiteral("org.kde.latte.spacer"));
    }
}

void DockConfigView::hideConfigWindow()
{
    if (m_shellSurface) {
        //!NOTE: Avoid crash in wayland enviroment with qt5.9
        close();
    } else {
        hide();
    }
}

void DockConfigView::updateLaunchersForGroup(int groupInt)
{
    Dock::LaunchersGroup group = (Dock::LaunchersGroup)groupInt;

    auto *dockCorona = qobject_cast<DockCorona *>(m_dockView->corona());

    //! when the layout/global launchers list is empty then the current dock launchers are used for them
    //! as a start point
    if (dockCorona &&  m_dockView->managedLayout()) {
        if ((group == Dock::LayoutLaunchers && m_dockView->managedLayout()->launchers().isEmpty())
            || (group == Dock::GlobalLaunchers && dockCorona->universalSettings()->launchers().isEmpty())) {

            Plasma::Containment *c = m_dockView->containment();

            const auto &applets = c->applets();

            for (auto *applet : applets) {
                KPluginMetaData meta = applet->kPackage().metadata();

                if (meta.pluginId() == "org.kde.latte.plasmoid") {
                    if (QQuickItem *appletInterface = applet->property("_plasma_graphicObject").value<QQuickItem *>()) {
                        const auto &childItems = appletInterface->childItems();

                        if (childItems.isEmpty()) {
                            continue;
                        }

                        for (QQuickItem *item : childItems) {
                            if (auto *metaObject = item->metaObject()) {
                                // not using QMetaObject::invokeMethod to avoid warnings when calling
                                // this on applets that don't have it or other child items since this
                                // is pretty much trial and error.
                                // Also, "var" arguments are treated as QVariant in QMetaObject

                                int methodIndex = metaObject->indexOfMethod("getLauncherList()");

                                if (methodIndex == -1) {
                                    continue;
                                }

                                QMetaMethod method = metaObject->method(methodIndex);

                                QVariant launchers;

                                if (method.invoke(item, Q_RETURN_ARG(QVariant, launchers))) {
                                    if (group == Dock::LayoutLaunchers) {
                                        m_dockView->managedLayout()->setLaunchers(launchers.toStringList());
                                    } else if (group == Dock::GlobalLaunchers) {
                                        dockCorona->universalSettings()->setLaunchers(launchers.toStringList());
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

}

//!BEGIN borders
Plasma::FrameSvg::EnabledBorders DockConfigView::enabledBorders() const
{
    return m_enabledBorders;
}

void DockConfigView::updateEnabledBorders()
{
    if (!this->screen()) {
        return;
    }

    Plasma::FrameSvg::EnabledBorders borders = Plasma::FrameSvg::AllBorders;

    switch (m_dockView->location()) {
        case Plasma::Types::TopEdge:
            borders &= m_inReverse ? ~Plasma::FrameSvg::BottomBorder : ~Plasma::FrameSvg::TopBorder;
            break;

        case Plasma::Types::LeftEdge:
            borders &= ~Plasma::FrameSvg::LeftBorder;
            break;

        case Plasma::Types::RightEdge:
            borders &= ~Plasma::FrameSvg::RightBorder;
            break;

        case Plasma::Types::BottomEdge:
            borders &= m_inReverse ? ~Plasma::FrameSvg::TopBorder : ~Plasma::FrameSvg::BottomBorder;
            break;

        default:
            break;
    }

    if (m_enabledBorders != borders) {
        m_enabledBorders = borders;

        if (mask() == QRect()) {
            PanelShadows::self()->addWindow(this, m_enabledBorders);
        }

        emit enabledBordersChanged();
    }
}

//!END borders


}
// kate: indent-mode cstyle; indent-width 4; replace-tabs on;
