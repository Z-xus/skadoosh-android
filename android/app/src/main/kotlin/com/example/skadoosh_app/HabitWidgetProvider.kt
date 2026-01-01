package com.example.skadoosh_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class HabitWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.habit_widget).apply {
                val widgetData = HomeWidgetPlugin.getData(context)
                val habitCompleted = widgetData.getInt("habit_completed", 0)
                val habitTotal = widgetData.getInt("habit_total", 0)
                val habitProgress = widgetData.getInt("habit_progress", 0)
                
                // Get individual habit data
                val habit1Id = widgetData.getInt("habit_1_id", -1)
                val habit1Title = widgetData.getString("habit_1_title", "")
                val habit1Done = widgetData.getBoolean("habit_1_done", false)
                
                val habit2Id = widgetData.getInt("habit_2_id", -1)
                val habit2Title = widgetData.getString("habit_2_title", "")
                val habit2Done = widgetData.getBoolean("habit_2_done", false)
                
                val habit3Id = widgetData.getInt("habit_3_id", -1)
                val habit3Title = widgetData.getString("habit_3_title", "")
                val habit3Done = widgetData.getBoolean("habit_3_done", false)
                
                val habit4Id = widgetData.getInt("habit_4_id", -1)
                val habit4Title = widgetData.getString("habit_4_title", "")
                val habit4Done = widgetData.getBoolean("habit_4_done", false)
                
                val habit5Id = widgetData.getInt("habit_5_id", -1)
                val habit5Title = widgetData.getString("habit_5_title", "")
                val habit5Done = widgetData.getBoolean("habit_5_done", false)
                
                setTextViewText(R.id.widget_habit_title, "Today's Habits")
                setTextViewText(R.id.widget_habit_count, "$habitCompleted / $habitTotal")
                setProgressBar(R.id.widget_habit_progress, 100, habitProgress, false)
                
                // Show or hide habits based on data
                if (habitTotal == 0) {
                    setViewVisibility(R.id.widget_habit_empty, View.VISIBLE)
                    setViewVisibility(R.id.widget_habit_1, View.GONE)
                    setViewVisibility(R.id.widget_habit_2, View.GONE)
                    setViewVisibility(R.id.widget_habit_3, View.GONE)
                    setViewVisibility(R.id.widget_habit_4, View.GONE)
                    setViewVisibility(R.id.widget_habit_5, View.GONE)
                } else {
                    setViewVisibility(R.id.widget_habit_empty, View.GONE)
                    
                    // Setup habit 1
                    if (habit1Id != -1 && !habit1Title.isNullOrEmpty()) {
                        setViewVisibility(R.id.widget_habit_1, View.VISIBLE)
                        setTextViewText(R.id.widget_habit_1, "${if (habit1Done) "✓" else "○"} $habit1Title")
                        setOnClickPendingIntent(R.id.widget_habit_1, createHabitToggleIntent(context, habit1Id, widgetId))
                    } else {
                        setViewVisibility(R.id.widget_habit_1, View.GONE)
                    }
                    
                    // Setup habit 2
                    if (habit2Id != -1 && !habit2Title.isNullOrEmpty()) {
                        setViewVisibility(R.id.widget_habit_2, View.VISIBLE)
                        setTextViewText(R.id.widget_habit_2, "${if (habit2Done) "✓" else "○"} $habit2Title")
                        setOnClickPendingIntent(R.id.widget_habit_2, createHabitToggleIntent(context, habit2Id, widgetId))
                    } else {
                        setViewVisibility(R.id.widget_habit_2, View.GONE)
                    }
                    
                    // Setup habit 3
                    if (habit3Id != -1 && !habit3Title.isNullOrEmpty()) {
                        setViewVisibility(R.id.widget_habit_3, View.VISIBLE)
                        setTextViewText(R.id.widget_habit_3, "${if (habit3Done) "✓" else "○"} $habit3Title")
                        setOnClickPendingIntent(R.id.widget_habit_3, createHabitToggleIntent(context, habit3Id, widgetId))
                    } else {
                        setViewVisibility(R.id.widget_habit_3, View.GONE)
                    }
                    
                    // Setup habit 4
                    if (habit4Id != -1 && !habit4Title.isNullOrEmpty()) {
                        setViewVisibility(R.id.widget_habit_4, View.VISIBLE)
                        setTextViewText(R.id.widget_habit_4, "${if (habit4Done) "✓" else "○"} $habit4Title")
                        setOnClickPendingIntent(R.id.widget_habit_4, createHabitToggleIntent(context, habit4Id, widgetId))
                    } else {
                        setViewVisibility(R.id.widget_habit_4, View.GONE)
                    }
                    
                    // Setup habit 5
                    if (habit5Id != -1 && !habit5Title.isNullOrEmpty()) {
                        setViewVisibility(R.id.widget_habit_5, View.VISIBLE)
                        setTextViewText(R.id.widget_habit_5, "${if (habit5Done) "✓" else "○"} $habit5Title")
                        setOnClickPendingIntent(R.id.widget_habit_5, createHabitToggleIntent(context, habit5Id, widgetId))
                    } else {
                        setViewVisibility(R.id.widget_habit_5, View.GONE)
                    }
                }
            }
            
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
    
    private fun createHabitToggleIntent(context: Context, habitId: Int, widgetId: Int): PendingIntent {
        // Create broadcast intent instead of activity intent
        val intent = Intent(context, WidgetActionReceiver::class.java).apply {
            action = WidgetActionReceiver.ACTION_TOGGLE_HABIT
            putExtra(WidgetActionReceiver.EXTRA_HABIT_ID, habitId)
            putExtra(WidgetActionReceiver.EXTRA_WIDGET_ID, widgetId)
        }
        
        return PendingIntent.getBroadcast(
            context,
            habitId, // Use habitId to make each habit click unique
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
