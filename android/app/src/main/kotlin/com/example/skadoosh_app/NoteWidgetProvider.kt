package com.example.skadoosh_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class NoteWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.note_widget).apply {
                val widgetData = HomeWidgetPlugin.getData(context)
                val noteTitle = widgetData.getString("note_title", "No Notes")
                val noteContent = widgetData.getString("note_content", "Create your first note to see it here!")
                
                setTextViewText(R.id.widget_note_title, noteTitle)
                setTextViewText(R.id.widget_note_content, noteContent)
                
                // Create intent with URI data
                val intent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    data = Uri.parse("skadoosh://widget?action=SELECT_NOTE_FOR_WIDGET&widget_id=$widgetId")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    widgetId,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                
                setOnClickPendingIntent(R.id.widget_note_container, pendingIntent)
            }
            
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
