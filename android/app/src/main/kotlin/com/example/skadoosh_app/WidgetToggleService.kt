package com.example.skadoosh_app

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class WidgetToggleService : Service() {
    private val TAG = "WidgetToggleService"
    private val CHANNEL = "com.example.skadoosh_app/widget"
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service started")
        
        if (intent != null) {
            val action = intent.getStringExtra("action")
            Log.d(TAG, "Action: $action")
            
            when (action) {
                "TOGGLE_HABIT" -> {
                    val habitId = intent.getIntExtra("habit_id", -1)
                    val widgetId = intent.getIntExtra("widget_id", -1)
                    Log.d(TAG, "TOGGLE_HABIT: habitId=$habitId")
                    
                    if (habitId != -1) {
                        sendToFlutter("TOGGLE_HABIT", habitId, widgetId)
                    }
                }
                "TOGGLE_TASK" -> {
                    val taskId = intent.getIntExtra("task_id", -1)
                    val widgetId = intent.getIntExtra("widget_id", -1)
                    Log.d(TAG, "TOGGLE_TASK: taskId=$taskId")
                    
                    if (taskId != -1) {
                        sendToFlutter("TOGGLE_TASK", taskId, widgetId)
                    }
                }
            }
        }
        
        // Stop the service after handling
        stopSelf(startId)
        return START_NOT_STICKY
    }
    
    private fun sendToFlutter(action: String, itemId: Int, widgetId: Int) {
        try {
            // Try to get cached Flutter engine
            var flutterEngine = FlutterEngineCache.getInstance().get("default_engine")
            
            if (flutterEngine == null) {
                Log.d(TAG, "No cached engine, starting MainActivity to initialize Flutter")
                // Need to start MainActivity to initialize Flutter engine
                val mainIntent = Intent(applicationContext, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    putExtra("widget_action", action)
                    putExtra(if (action == "TOGGLE_HABIT") "habit_id" else "task_id", itemId)
                    putExtra("widget_id", widgetId)
                }
                applicationContext.startActivity(mainIntent)
            } else {
                // Engine exists, send message
                Log.d(TAG, "Found cached engine, sending message")
                val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                val uri = "skadoosh://widget?action=$action&${if (action == "TOGGLE_HABIT") "habit" else "task"}_id=$itemId&widget_id=$widgetId"
                
                Log.d(TAG, "Sending to Flutter: $uri")
                channel.invokeMethod("handleWidgetAction", mapOf(
                    "action" to action,
                    "uri" to uri
                ))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error: ${e.message}", e)
        }
    }
}
