package com.example.skadoosh_app

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class TransparentWidgetActivity : Activity() {
    private val CHANNEL = "com.example.skadoosh_app/widget"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Make window transparent
        window.setBackgroundDrawableResource(android.R.color.transparent)
        
        // Handle the widget action
        handleWidgetAction()
    }
    
    private fun handleWidgetAction() {
        val widgetAction = intent.getStringExtra("widget_action")
        
        // Check if Flutter engine is already running
        val flutterEngine = FlutterEngineCache.getInstance().get("default_engine")
        
        if (flutterEngine != null) {
            // Engine exists, send message directly
            sendToggleMessage(flutterEngine, widgetAction)
            finish()
        } else {
            // No engine, start MainActivity properly
            val mainIntent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("widget_action", widgetAction)
                putExtra("habit_id", intent.getIntExtra("habit_id", -1))
                putExtra("task_id", intent.getIntExtra("task_id", -1))
                putExtra("widget_id", intent.getIntExtra("widget_id", -1))
                putExtra("from_widget", true)
            }
            startActivity(mainIntent)
            finish()
        }
    }
    
    private fun sendToggleMessage(flutterEngine: FlutterEngine, widgetAction: String?) {
        when (widgetAction) {
            "TOGGLE_HABIT" -> {
                val habitId = intent.getIntExtra("habit_id", -1)
                val widgetId = intent.getIntExtra("widget_id", -1)
                
                if (habitId != -1) {
                    val uri = "skadoosh://widget?action=TOGGLE_HABIT&habit_id=$habitId&widget_id=$widgetId"
                    val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                    channel.invokeMethod("handleWidgetAction", mapOf(
                        "action" to "TOGGLE_HABIT",
                        "uri" to uri
                    ))
                }
            }
            "TOGGLE_TASK" -> {
                val taskId = intent.getIntExtra("task_id", -1)
                val widgetId = intent.getIntExtra("widget_id", -1)
                
                if (taskId != -1) {
                    val uri = "skadoosh://widget?action=TOGGLE_TASK&task_id=$taskId&widget_id=$widgetId"
                    val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                    channel.invokeMethod("handleWidgetAction", mapOf(
                        "action" to "TOGGLE_TASK",
                        "uri" to uri
                    ))
                }
            }
        }
    }
}
