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

class TaskWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.task_widget).apply {
                val widgetData = HomeWidgetPlugin.getData(context)
                val taskCompleted = widgetData.getInt("task_completed", 0)
                val taskTotal = widgetData.getInt("task_total", 0)
                val taskProgress = widgetData.getInt("task_progress", 0)
                
                
                // Get individual task data
                val task1Id = widgetData.getInt("task_1_id", -1)
                val task1Title = widgetData.getString("task_1_title", "")
                val task1Done = widgetData.getBoolean("task_1_done", false)
                
                val task2Id = widgetData.getInt("task_2_id", -1)
                val task2Title = widgetData.getString("task_2_title", "")
                val task2Done = widgetData.getBoolean("task_2_done", false)
                
                val task3Id = widgetData.getInt("task_3_id", -1)
                val task3Title = widgetData.getString("task_3_title", "")
                val task3Done = widgetData.getBoolean("task_3_done", false)
                
                val task4Id = widgetData.getInt("task_4_id", -1)
                val task4Title = widgetData.getString("task_4_title", "")
                val task4Done = widgetData.getBoolean("task_4_done", false)
                
                val task5Id = widgetData.getInt("task_5_id", -1)
                val task5Title = widgetData.getString("task_5_title", "")
                val task5Done = widgetData.getBoolean("task_5_done", false)
                
                setTextViewText(R.id.widget_task_title, "Today's Tasks")
                setTextViewText(R.id.widget_task_count, "$taskCompleted / $taskTotal")
                setProgressBar(R.id.widget_task_progress, 100, taskProgress, false)
                
                // Show or hide tasks based on data
                if (taskTotal == 0) {
                    setViewVisibility(R.id.widget_task_empty, View.VISIBLE)
                    setViewVisibility(R.id.widget_task_1, View.GONE)
                    setViewVisibility(R.id.widget_task_2, View.GONE)
                    setViewVisibility(R.id.widget_task_3, View.GONE)
                    setViewVisibility(R.id.widget_task_4, View.GONE)
                    setViewVisibility(R.id.widget_task_5, View.GONE)
                } else {
                    setViewVisibility(R.id.widget_task_empty, View.GONE)
                    
                    // Setup task 1
                    if (task1Id != -1 && !task1Title.isNullOrEmpty()) {
                        setViewVisibility(R.id.widget_task_1, View.VISIBLE)
                        setTextViewText(R.id.widget_task_1, "${if (task1Done) "✓" else "○"} $task1Title")
                        setOnClickPendingIntent(R.id.widget_task_1, createTaskToggleIntent(context, task1Id, widgetId))
                    } else {
                        setViewVisibility(R.id.widget_task_1, View.GONE)
                    }
                    
                    // Setup task 2
                    if (task2Id != -1 && !task2Title.isNullOrEmpty()) {
                        setViewVisibility(R.id.widget_task_2, View.VISIBLE)
                        setTextViewText(R.id.widget_task_2, "${if (task2Done) "✓" else "○"} $task2Title")
                        setOnClickPendingIntent(R.id.widget_task_2, createTaskToggleIntent(context, task2Id, widgetId))
                    } else {
                        setViewVisibility(R.id.widget_task_2, View.GONE)
                    }
                    
                    // Setup task 3
                    if (task3Id != -1 && !task3Title.isNullOrEmpty()) {
                        setViewVisibility(R.id.widget_task_3, View.VISIBLE)
                        setTextViewText(R.id.widget_task_3, "${if (task3Done) "✓" else "○"} $task3Title")
                        setOnClickPendingIntent(R.id.widget_task_3, createTaskToggleIntent(context, task3Id, widgetId))
                    } else {
                        setViewVisibility(R.id.widget_task_3, View.GONE)
                    }
                    
                    // Setup task 4
                    if (task4Id != -1 && !task4Title.isNullOrEmpty()) {
                        setViewVisibility(R.id.widget_task_4, View.VISIBLE)
                        setTextViewText(R.id.widget_task_4, "${if (task4Done) "✓" else "○"} $task4Title")
                        setOnClickPendingIntent(R.id.widget_task_4, createTaskToggleIntent(context, task4Id, widgetId))
                    } else {
                        setViewVisibility(R.id.widget_task_4, View.GONE)
                    }
                    
                    // Setup task 5
                    if (task5Id != -1 && !task5Title.isNullOrEmpty()) {
                        setViewVisibility(R.id.widget_task_5, View.VISIBLE)
                        setTextViewText(R.id.widget_task_5, "${if (task5Done) "✓" else "○"} $task5Title")
                        setOnClickPendingIntent(R.id.widget_task_5, createTaskToggleIntent(context, task5Id, widgetId))
                    } else {
                        setViewVisibility(R.id.widget_task_5, View.GONE)
                    }
                }
            }
            
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
    
    private fun createTaskToggleIntent(context: Context, taskId: Int, widgetId: Int): PendingIntent {
        // Create broadcast intent instead of activity intent
        val intent = Intent(context, WidgetActionReceiver::class.java).apply {
            action = WidgetActionReceiver.ACTION_TOGGLE_TASK
            putExtra(WidgetActionReceiver.EXTRA_TASK_ID, taskId)
            putExtra(WidgetActionReceiver.EXTRA_WIDGET_ID, widgetId)
        }
        
        return PendingIntent.getBroadcast(
            context,
            10000 + taskId, // Use offset to avoid collision with habit IDs
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
    
    companion object {
        private const val TAG = "TaskWidgetProvider"
    }
}
