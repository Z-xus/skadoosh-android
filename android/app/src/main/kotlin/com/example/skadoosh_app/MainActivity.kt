package com.example.skadoosh_app

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.skadoosh_app/widget"
    private var methodChannel: MethodChannel? = null
    private var isFromWidget = false
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Cache the engine
        FlutterEngineCache.getInstance().put("default_engine", flutterEngine)
        
        // Create method channel for widget communication
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }
    
    private fun handleIntent(intent: Intent?) {
        // Check if this is from widget
        isFromWidget = intent?.getBooleanExtra("from_widget", false) ?: false
        
        // Handle widget action extras
        val widgetAction = intent?.getStringExtra("widget_action")
        if (widgetAction != null) {
            // Wait for Flutter engine to be ready
            Handler(Looper.getMainLooper()).postDelayed({
                when (widgetAction) {
                    "TOGGLE_HABIT" -> {
                        val habitId = intent.getIntExtra("habit_id", -1)
                        val widgetId = intent.getIntExtra("widget_id", -1)
                        
                        if (habitId != -1) {
                            val uri = "skadoosh://widget?action=TOGGLE_HABIT&habit_id=$habitId&widget_id=$widgetId"
                            methodChannel?.invokeMethod("handleWidgetAction", mapOf(
                                "action" to "TOGGLE_HABIT",
                                "uri" to uri
                            ))
                        }
                        
                        // Move to background if started from widget
                        if (isFromWidget) {
                            Handler(Looper.getMainLooper()).postDelayed({
                                moveTaskToBack(true)
                            }, 100)
                        }
                    }
                    "TOGGLE_TASK" -> {
                        val taskId = intent.getIntExtra("task_id", -1)
                        val widgetId = intent.getIntExtra("widget_id", -1)
                        
                        if (taskId != -1) {
                            val uri = "skadoosh://widget?action=TOGGLE_TASK&task_id=$taskId&widget_id=$widgetId"
                            methodChannel?.invokeMethod("handleWidgetAction", mapOf(
                                "action" to "TOGGLE_TASK",
                                "uri" to uri
                            ))
                        }
                        
                        // Move to background if started from widget
                        if (isFromWidget) {
                            Handler(Looper.getMainLooper()).postDelayed({
                                moveTaskToBack(true)
                            }, 100)
                        }
                    }
                }
            }, 200)
            
            return
        }
        
        // Handle URI-based intents
        if (intent?.action == Intent.ACTION_VIEW && intent.data != null) {
            val uri = intent.data!!
            val action = uri.getQueryParameter("action")
            
            // Send to Flutter via method channel
            methodChannel?.invokeMethod("handleWidgetAction", mapOf(
                "action" to action,
                "uri" to uri.toString()
            ))
        }
    }
}
