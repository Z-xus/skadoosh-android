package com.example.skadoosh_app

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class WidgetTransparentActivity : Activity() {
    private val TAG = "WidgetTransparent"
    private val CHANNEL = "com.example.skadoosh_app/widget"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "WidgetTransparentActivity created")
        
        // Make this activity transparent and not show in UI
        setTheme(android.R.style.Theme_Translucent_NoTitleBar)
        
        handleWidgetAction()
        
        // Finish immediately
        finish()
    }
    
    private fun handleWidgetAction() {
        val widgetAction = intent.getStringExtra("widget_action")
        Log.d(TAG, "Widget action: $widgetAction")
        
        when (widgetAction) {
            "TOGGLE_HABIT" -> {
                val habitId = intent.getIntExtra("habit_id", -1)
                val widgetId = intent.getIntExtra("widget_id", -1)
                Log.d(TAG, "TOGGLE_HABIT: habitId=$habitId, widgetId=$widgetId")
                
                if (habitId != -1) {
                    sendToFlutter("TOGGLE_HABIT", habitId, widgetId)
                }
            }
            "TOGGLE_TASK" -> {
                val taskId = intent.getIntExtra("task_id", -1)
                val widgetId = intent.getIntExtra("widget_id", -1)
                Log.d(TAG, "TOGGLE_TASK: taskId=$taskId, widgetId=$widgetId")
                
                if (taskId != -1) {
                    sendToFlutter("TOGGLE_TASK", taskId, widgetId)
                }
            }
        }
    }
    
    private fun sendToFlutter(action: String, itemId: Int, widgetId: Int) {
        try {
            // Try to get cached Flutter engine from MainActivity
            var flutterEngine = FlutterEngineCache.getInstance().get("default_engine")
            
            if (flutterEngine == null) {
                Log.d(TAG, "No cached engine, creating new one")
                // Create a new Flutter engine if none exists
                flutterEngine = FlutterEngine(applicationContext)
                flutterEngine.dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint.createDefault()
                )
                FlutterEngineCache.getInstance().put("default_engine", flutterEngine)
            }
            
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            val uri = "skadoosh://widget?action=$action&${if (action == "TOGGLE_HABIT") "habit" else "task"}_id=$itemId&widget_id=$widgetId"
            
            Log.d(TAG, "Sending to Flutter: $uri")
            channel.invokeMethod("handleWidgetAction", mapOf(
                "action" to action,
                "uri" to uri
            ))
        } catch (e: Exception) {
            Log.e(TAG, "Error sending to Flutter: ${e.message}")
        }
    }
}
