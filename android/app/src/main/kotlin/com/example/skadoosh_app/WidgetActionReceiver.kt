package com.example.skadoosh_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class WidgetActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        
        when (action) {
            ACTION_TOGGLE_HABIT -> {
                val habitId = intent.getIntExtra(EXTRA_HABIT_ID, -1)
                val widgetId = intent.getIntExtra(EXTRA_WIDGET_ID, -1)
                
                if (habitId != -1) {
                    val activityIntent = Intent(context, TransparentWidgetActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_ANIMATION or Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS
                        putExtra("widget_action", "TOGGLE_HABIT")
                        putExtra("habit_id", habitId)
                        putExtra("widget_id", widgetId)
                    }
                    context.startActivity(activityIntent)
                }
            }
            ACTION_TOGGLE_TASK -> {
                val taskId = intent.getIntExtra(EXTRA_TASK_ID, -1)
                val widgetId = intent.getIntExtra(EXTRA_WIDGET_ID, -1)
                
                if (taskId != -1) {
                    val activityIntent = Intent(context, TransparentWidgetActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_ANIMATION or Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS
                        putExtra("widget_action", "TOGGLE_TASK")
                        putExtra("task_id", taskId)
                        putExtra("widget_id", widgetId)
                    }
                    context.startActivity(activityIntent)
                }
            }
        }
    }
    
    companion object {
        const val ACTION_TOGGLE_HABIT = "com.example.skadoosh_app.TOGGLE_HABIT"
        const val ACTION_TOGGLE_TASK = "com.example.skadoosh_app.TOGGLE_TASK"
        const val EXTRA_HABIT_ID = "habit_id"
        const val EXTRA_TASK_ID = "task_id"
        const val EXTRA_WIDGET_ID = "widget_id"
    }
}
