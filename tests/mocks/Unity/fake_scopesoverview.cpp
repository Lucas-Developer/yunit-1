/*
 * Copyright (C) 2014 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "fake_scopesoverview.h"

#include "fake_scopes.h"

#include <paths.h>

ScopesOverview::ScopesOverview(Scopes* parent)
 : Scope("scopesOverview", "Scopes Overview", false, parent)
{
    m_searchCategories = m_categories; // save the usual categories as search result
    m_scopesOverviewCategories = new ScopesOverviewCategories(parent, this);
    m_categories = m_scopesOverviewCategories;
}

void ScopesOverview::setSearchQuery(const QString& search_query)
{
    Scope::setSearchQuery(search_query);

    auto origCategories = m_categories;
    if (search_query.isEmpty()) m_categories = m_scopesOverviewCategories;
    else m_categories = m_searchCategories;

    if (m_categories != origCategories)
        Q_EMIT categoriesChanged();
}


ScopesOverviewCategories::ScopesOverviewCategories(Scopes *scopes, QObject* parent)
    : unity::shell::scopes::CategoriesInterface(parent)
    , m_scopes(scopes)
{
}

int ScopesOverviewCategories::rowCount(const QModelIndex& /*parent*/) const
{
    return 2;
}

void ScopesOverviewCategories::addSpecialCategory(QString const&, QString const&, QString const&, QString const&, QObject*)
{
    qFatal("Using un-implemented ScopesOverviewCategories::addSpecialCategory");
}

bool ScopesOverviewCategories::overrideCategoryJson(QString const& /* categoryId */, QString const& /* json */)
{
    qFatal("Using un-implemented ScopesOverviewCategories::overrideCategoryJson");
}

QVariant
ScopesOverviewCategories::data(const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }

    unity::shell::scopes::ResultsModelInterface *resultsModel = m_resultsModels[index.row()];
    if (!resultsModel) {
        QObject *that = const_cast<ScopesOverviewCategories*>(this);
        resultsModel = new ScopesOverviewResultsModel(m_scopes, index.row() == 0, that);
        m_resultsModels[index.row()] = resultsModel;
    }
    switch (role) {
        case RoleCategoryId:
            return index.row() == 0 ? "favorites" : "all";
        case RoleName:
            return index.row() == 0 ? "Favorites" : "All";
        case RoleIcon:
            return QVariant();
        case RoleRawRendererTemplate:
            qFatal("Using un-implemented RoleRawRendererTemplate Categories role");
            return QVariant();
        case RoleRenderer:
        {
            QVariantMap map;
            map["category-layout"] = "grid";
            map["card-size"] = "small";
            map["overlay"] = true;
            return map;
        }
        case RoleComponents:
        {
            QVariantMap map, artMap;
            artMap["aspect-ratio"] = "0.5";
            artMap["field"] = "art";
            map["art"] = artMap;
            map["title"] = "HOLA";
            return map;
        }
        case RoleResults:
            return QVariant::fromValue(resultsModel);
        case RoleCount:
            return resultsModel->rowCount();
        default:
            qFatal("Using un-implemented Categories role");
            return QVariant();
    }
}



ScopesOverviewResultsModel::ScopesOverviewResultsModel(Scopes *scopes, bool isFavoriteCategory, QObject* parent)
    : unity::shell::scopes::ResultsModelInterface(parent)
    , m_scopes(scopes)
    , m_isFavoriteCategory(isFavoriteCategory)
{
}

QString ScopesOverviewResultsModel::categoryId() const
{
    return m_isFavoriteCategory ? "favorites" : "all";
}

void ScopesOverviewResultsModel::setCategoryId(QString const& /*id*/)
{
    qFatal("Calling un-implemented ScopesOverviewResultsModel::setCategoryId");
}

int ScopesOverviewResultsModel::scopeIndex(QString const& id) const
{
    const int scopeCount = count();
    for (int i = 0; i < scopeCount; ++i) {
        if (m_scopes->scopeAt(i, m_isFavoriteCategory)->id() == id)
            return i;
    }
    return -1;
}

QHash<int, QByteArray> ScopesOverviewResultsModel::roleNames() const
{
    QHash<int, QByteArray> roles = unity::shell::scopes::ResultsModelInterface::roleNames();
    roles[RoleBackground + 1] = "scopeId";
    return roles;
}

int ScopesOverviewResultsModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);

    return m_scopes->count(m_isFavoriteCategory);
}

int ScopesOverviewResultsModel::count() const
{
    return rowCount();
}

QVariant
ScopesOverviewResultsModel::data(const QModelIndex& index, int role) const
{
    switch (role) {
        case RoleUri:
        case RoleCategoryId:
        case RoleDndUri:
            return QString();
        case RoleResult:
            return m_scopes->scopeAt(index.row(), m_isFavoriteCategory)->id();
        case RoleTitle:
            return m_scopes->scopeAt(index.row(), m_isFavoriteCategory)->name();
        case RoleArt:
            return qmlDirectory() + "graphics/applicationIcons/dash.png";
        case RoleMascot:
        case RoleEmblem:
        case RoleSummary:
        case RoleBackground + 1: // scopeId
            return m_scopes->scopeAt(index.row(), m_isFavoriteCategory)->id();
            break;
        default:
            return QVariant();
    }
}
