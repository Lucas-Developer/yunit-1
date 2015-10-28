// unity-api
#include <unity/shell/application/ApplicationManagerInterface.h>
#include <unity/shell/application/ApplicationInfoInterface.h>

#include "applicationsfiltermodel.h"

using namespace unity::shell::application;

ApplicationsFilterModel::ApplicationsFilterModel(QObject *parent):
    QSortFilterProxyModel(parent),
    m_appModel(nullptr),
    m_filterTouchApps(false),
    m_filterLegacyApps(false)
{
}

ApplicationManagerInterface *ApplicationsFilterModel::applicationsModel() const
{
    return m_appModel;
}

void ApplicationsFilterModel::setApplicationsModel(ApplicationManagerInterface *applicationsModel)
{
    if (m_appModel) {
        disconnect(m_appModel, &ApplicationManagerInterface::countChanged, this, &ApplicationsFilterModel::countChanged);
    }
    if (m_appModel != applicationsModel) {
        m_appModel = applicationsModel;
        setSourceModel(m_appModel);
        Q_EMIT applicationsModelChanged();
        connect(m_appModel, &ApplicationManagerInterface::countChanged, this, &ApplicationsFilterModel::countChanged);
    }
}

bool ApplicationsFilterModel::filterTouchApps() const
{
    return m_filterTouchApps;
}

void ApplicationsFilterModel::setFilterTouchApps(bool filterTouchApps)
{
    if (m_filterTouchApps != filterTouchApps) {
        m_filterTouchApps = filterTouchApps;
        Q_EMIT filterTouchAppsChanged();

        invalidateFilter();
        Q_EMIT countChanged();
    }
}

bool ApplicationsFilterModel::filterLegacyApps() const
{
    return m_filterLegacyApps;
}

void ApplicationsFilterModel::setFilterLegacyApps(bool filterLegacyApps)
{
    if (m_filterLegacyApps != filterLegacyApps) {
        m_filterLegacyApps = filterLegacyApps;
        Q_EMIT filterLegacyAppsChanged();

        invalidateFilter();
        Q_EMIT countChanged();
    }
}

bool ApplicationsFilterModel::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
{
    Q_UNUSED(source_parent);

    ApplicationInfoInterface *app = m_appModel->get(source_row);
    Q_ASSERT(app);
    if (m_filterLegacyApps && !app->isTouchApp()) {
        return false;
    }
    if (m_filterTouchApps && app->isTouchApp()) {
        return false;
    }
    return true;
}

ApplicationInfoInterface *ApplicationsFilterModel::get(int index) const
{
    return m_appModel->get(mapToSource(this->index(index, 0)).row());
}
