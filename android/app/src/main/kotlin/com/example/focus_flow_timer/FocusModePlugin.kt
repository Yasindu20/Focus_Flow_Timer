package com.example.focus_flow_timer

import android.app.Activity
import android.app.NotificationManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.PixelFormat
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import android.widget.Button
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.*
import kotlin.collections.HashMap

class FocusModePlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var context: Context? = null
    private var windowManager: WindowManager? = null
    private var overlayViews = mutableMapOf<String, View>()
    
    // Focus mode state
    private var isFocusModeActive = false
    private var blockedApps = mutableSetOf<String>()
    private var isGentleMode = false
    
    // DND state tracking
    private var originalInterruptionFilter: Int? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "focus_mode/android")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        windowManager = context?.getSystemService(Context.WINDOW_SERVICE) as WindowManager?
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        try {
            when (call.method) {
                "canBlockApps" -> {
                    result.success(canDrawOverlays())
                }
                "getInstalledApps" -> {
                    result.success(getInstalledApps())
                }
                "enableDoNotDisturb" -> {
                    val allowEmergency = call.argument<Boolean>("allowEmergency") ?: true
                    val level = call.argument<Int>("level") ?: 1
                    result.success(enableDoNotDisturb(allowEmergency, level))
                }
                "disableDoNotDisturb" -> {
                    result.success(disableDoNotDisturb())
                }
                "configureAppBlocking" -> {
                    val blockingLevel = call.argument<Int>("blockingLevel") ?: 1
                    val distractingApps = call.argument<List<String>>("distractingApps") ?: emptyList()
                    val allowedApps = call.argument<List<String>>("allowedApps") ?: emptyList()
                    val gentleMode = call.argument<Boolean>("gentleMode") ?: false
                    result.success(configureAppBlocking(blockingLevel, distractingApps, allowedApps, gentleMode))
                }
                "removeAppBlocking" -> {
                    result.success(removeAppBlocking())
                }
                "startFocusMonitoring" -> {
                    val durationMs = call.argument<Long>("durationMs") ?: 0L
                    val monitoringLevel = call.argument<Int>("monitoringLevel") ?: 1
                    result.success(startFocusMonitoring(durationMs, monitoringLevel))
                }
                "stopFocusMonitoring" -> {
                    result.success(stopFocusMonitoring())
                }
                else -> {
                    result.notImplemented()
                }
            }
        } catch (e: Exception) {
            result.error("FOCUS_MODE_ERROR", e.message, null)
        }
    }

    private fun canDrawOverlays(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(context)
        } else {
            true
        }
    }

    private fun getInstalledApps(): List<Map<String, Any>> {
        val apps = mutableListOf<Map<String, Any>>()
        try {
            val packageManager = context?.packageManager ?: return apps
            val installedApps = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
            
            for (app in installedApps) {
                // Skip system apps unless they're commonly distracting
                if (app.flags and ApplicationInfo.FLAG_SYSTEM != 0) {
                    continue
                }
                
                val appInfo = mapOf(
                    "packageName" to app.packageName,
                    "displayName" to packageManager.getApplicationLabel(app).toString(),
                    "isSystemApp" to (app.flags and ApplicationInfo.FLAG_SYSTEM != 0)
                )
                apps.add(appInfo)
            }
        } catch (e: Exception) {
            // Return empty list if error occurs
        }
        return apps
    }

    private fun enableDoNotDisturb(allowEmergency: Boolean, level: Int): Boolean {
        try {
            val notificationManager = context?.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                ?: return false

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (!notificationManager.isNotificationPolicyAccessGranted) {
                    // Request DND access
                    val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    context?.startActivity(intent)
                    return false
                }

                // Store original state
                originalInterruptionFilter = notificationManager.currentInterruptionFilter

                // Set DND mode based on level and settings
                val interruptionFilter = when {
                    level >= 3 -> NotificationManager.INTERRUPTION_FILTER_NONE // Strict mode
                    level >= 2 -> if (allowEmergency) NotificationManager.INTERRUPTION_FILTER_PRIORITY 
                                  else NotificationManager.INTERRUPTION_FILTER_ALARMS // Moderate mode
                    else -> NotificationManager.INTERRUPTION_FILTER_PRIORITY // Gentle mode
                }

                notificationManager.setInterruptionFilter(interruptionFilter)
                return true
            }
        } catch (e: Exception) {
            // Handle exception
        }
        return false
    }

    private fun disableDoNotDisturb(): Boolean {
        try {
            val notificationManager = context?.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                ?: return false

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                // Restore original interruption filter or set to all
                val filterToSet = originalInterruptionFilter ?: NotificationManager.INTERRUPTION_FILTER_ALL
                notificationManager.setInterruptionFilter(filterToSet)
                originalInterruptionFilter = null
                return true
            }
        } catch (e: Exception) {
            // Handle exception
        }
        return false
    }

    private fun configureAppBlocking(
        blockingLevel: Int,
        distractingApps: List<String>,
        allowedApps: List<String>,
        gentleMode: Boolean
    ): Boolean {
        if (!canDrawOverlays()) {
            return false
        }

        try {
            isFocusModeActive = true
            isGentleMode = gentleMode
            
            // Set up blocked apps
            blockedApps.clear()
            blockedApps.addAll(distractingApps)
            blockedApps.removeAll(allowedApps.toSet())

            // Start app monitoring
            startAppMonitoring()
            
            return true
        } catch (e: Exception) {
            return false
        }
    }

    private fun removeAppBlocking(): Boolean {
        try {
            isFocusModeActive = false
            blockedApps.clear()
            
            // Remove all overlay views
            overlayViews.forEach { (_, view) ->
                try {
                    windowManager?.removeView(view)
                } catch (e: Exception) {
                    // View might already be removed
                }
            }
            overlayViews.clear()
            
            return true
        } catch (e: Exception) {
            return false
        }
    }

    private fun startFocusMonitoring(durationMs: Long, monitoringLevel: Int): Boolean {
        // This would typically involve setting up usage stats monitoring
        // For now, we'll implement basic monitoring
        return true
    }

    private fun stopFocusMonitoring(): Boolean {
        isFocusModeActive = false
        return removeAppBlocking()
    }

    private fun startAppMonitoring() {
        // In a real implementation, this would use UsageStatsManager
        // to monitor app usage and trigger blocking overlays
        
        // For demo purposes, we'll set up basic monitoring
        Timer().scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                if (!isFocusModeActive) {
                    cancel()
                    return
                }
                
                // Check current foreground app
                checkCurrentApp()
            }
        }, 0, 2000) // Check every 2 seconds
    }

    private fun checkCurrentApp() {
        try {
            // This is a simplified implementation
            // In a real app, you'd use UsageStatsManager to get the current foreground app
            
            // For now, we'll demonstrate with a placeholder
            val currentApp = getCurrentForegroundApp()
            if (currentApp != null && blockedApps.contains(currentApp)) {
                showBlockingOverlay(currentApp)
                
                // Notify Flutter about the blocked app
                channel.invokeMethod("onAppBlocked", mapOf(
                    "package" to currentApp,
                    "appName" to getAppName(currentApp)
                ))
            }
        } catch (e: Exception) {
            // Handle exception
        }
    }

    private fun getCurrentForegroundApp(): String? {
        // This requires PACKAGE_USAGE_STATS permission and UsageStatsManager
        // For demo purposes, returning null
        return null
    }

    private fun getAppName(packageName: String): String {
        return try {
            val packageManager = context?.packageManager
            val appInfo = packageManager?.getApplicationInfo(packageName, 0)
            packageManager?.getApplicationLabel(appInfo!!)?.toString() ?: packageName
        } catch (e: Exception) {
            packageName
        }
    }

    private fun showBlockingOverlay(packageName: String) {
        if (overlayViews.containsKey(packageName)) {
            return // Already showing overlay for this app
        }

        try {
            val inflater = LayoutInflater.from(context)
            val overlayView = inflater.inflate(R.layout.focus_mode_overlay, null)
            
            // Configure overlay content
            val messageText = overlayView.findViewById<TextView>(R.id.blockingMessage)
            val appNameText = overlayView.findViewById<TextView>(R.id.appName)
            val backToFocusButton = overlayView.findViewById<Button>(R.id.backToFocusButton)
            val overrideButton = overlayView.findViewById<Button>(R.id.overrideButton)
            
            appNameText.text = getAppName(packageName)
            
            if (isGentleMode) {
                messageText.text = "🎯 Stay focused! You're in the middle of a focus session."
                overrideButton.text = "Continue anyway (5s)"
                overrideButton.isEnabled = false
                
                // Enable override after 5 seconds in gentle mode
                Timer().schedule(object : TimerTask() {
                    override fun run() {
                        activity?.runOnUiThread {
                            overrideButton.isEnabled = true
                            overrideButton.text = "Continue anyway"
                        }
                    }
                }, 5000)
            } else {
                messageText.text = "🚫 App blocked during focus session"
                overrideButton.text = "Override (Break focus)"
            }

            backToFocusButton.setOnClickListener {
                removeOverlay(packageName)
                // Return to focus app
                val intent = context?.packageManager?.getLaunchIntentForPackage(context?.packageName ?: "")
                intent?.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                context?.startActivity(intent)
            }

            overrideButton.setOnClickListener {
                removeOverlay(packageName)
                // Notify Flutter about focus break
                channel.invokeMethod("onDistractionDetected", mapOf(
                    "package" to packageName,
                    "appName" to getAppName(packageName),
                    "action" to "override"
                ))
            }

            // Window parameters for overlay
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) 
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                else 
                    WindowManager.LayoutParams.TYPE_PHONE,
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or 
                WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
                PixelFormat.TRANSLUCENT
            )
            
            params.gravity = Gravity.CENTER

            windowManager?.addView(overlayView, params)
            overlayViews[packageName] = overlayView

        } catch (e: Exception) {
            // Handle exception
        }
    }

    private fun removeOverlay(packageName: String) {
        overlayViews[packageName]?.let { view ->
            try {
                windowManager?.removeView(view)
                overlayViews.remove(packageName)
            } catch (e: Exception) {
                // View might already be removed
            }
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        removeAppBlocking()
        context = null
        windowManager = null
    }
}