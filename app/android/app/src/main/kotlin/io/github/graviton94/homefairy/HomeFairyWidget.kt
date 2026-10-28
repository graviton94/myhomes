package io.github.graviton94.homefairy

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home screen widget: the last change, a search box that opens the app's
 * search, and what to use first / buy / get back. The app writes the
 * (already translated) lines with home_widget whenever the home changes.
 */
class HomeFairyWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.home_fairy_widget).apply {
                setTextViewText(R.id.widget_title, widgetData.getString("title", "Home Fairy"))
                setTextViewText(R.id.widget_change, widgetData.getString("change", ""))
                setTextViewText(R.id.widget_search, widgetData.getString("search", ""))
                setTextViewText(R.id.widget_counts, widgetData.getString("counts", ""))
                val detail = widgetData.getString("detail", "") ?: ""
                setTextViewText(R.id.widget_detail, detail)
                setViewVisibility(R.id.widget_detail, if (detail.isEmpty()) View.GONE else View.VISIBLE)
                setOnClickPendingIntent(R.id.widget_root, HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java))
                setOnClickPendingIntent(
                    R.id.widget_search,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("homefairy://search")),
                )
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
