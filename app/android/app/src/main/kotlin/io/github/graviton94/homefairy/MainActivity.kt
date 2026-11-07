package io.github.graviton94.homefairy

import android.app.Activity
import android.os.Build
import android.os.Bundle
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
import com.google.android.play.core.appupdate.AppUpdateInfo
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

// Fragment activity: the Naver login SDK needs it.
// Also the store's flexible in-app update (lib/data/app_update.dart).
class MainActivity : FlutterFragmentActivity() {
    private lateinit var updates: AppUpdateManager
    private lateinit var askUpdate: ActivityResultLauncher<IntentSenderRequest>
    private var pendingStart: MethodChannel.Result? = null
    private var sink: EventChannel.EventSink? = null
    private var lastInfo: AppUpdateInfo? = null

    private val listener = InstallStateUpdatedListener { s ->
        sink?.success(
            mapOf(
                "phase" to phaseOf(s.installStatus()),
                "downloaded" to s.bytesDownloaded(),
                "total" to s.totalBytesToDownload(),
            ),
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        updates = AppUpdateManagerFactory.create(this)
        askUpdate = registerForActivityResult(ActivityResultContracts.StartIntentSenderForResult()) { r ->
            pendingStart?.success(r.resultCode == Activity.RESULT_OK)
            pendingStart = null
        }
        updates.registerListener(listener)
    }

    override fun onDestroy() {
        updates.unregisterListener(listener)
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        EventChannel(messenger, "homefairy/update/events").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, events: EventChannel.EventSink?) {
                    sink = events
                }

                override fun onCancel(args: Any?) {
                    sink = null
                }
            },
        )
        MethodChannel(messenger, "homefairy/update").setMethodCallHandler { call, result ->
            when (call.method) {
                "check" -> check(result)
                "start" -> start(result)
                "complete" -> {
                    updates.completeUpdate()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun fromStore(): Boolean = try {
        val installer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            packageManager.getInstallSourceInfo(packageName).installingPackageName
        } else {
            @Suppress("DEPRECATION")
            packageManager.getInstallerPackageName(packageName)
        }
        installer == "com.android.vending"
    } catch (e: Exception) {
        false
    }

    private fun check(result: MethodChannel.Result) {
        if (!fromStore()) {
            result.success(mapOf("phase" to "notStore"))
            return
        }
        updates.appUpdateInfo
            .addOnSuccessListener { info ->
                lastInfo = info
                val phase = when {
                    info.installStatus() == InstallStatus.DOWNLOADED -> "downloaded"
                    info.installStatus() == InstallStatus.DOWNLOADING || info.installStatus() == InstallStatus.PENDING -> "downloading"
                    info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE &&
                        info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE) -> "available"
                    info.updateAvailability() == UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS -> "downloading"
                    else -> "latest"
                }
                result.success(
                    mapOf(
                        "phase" to phase,
                        "code" to info.availableVersionCode(),
                        "downloaded" to info.bytesDownloaded(),
                        "total" to info.totalBytesToDownload(),
                    ),
                )
            }
            .addOnFailureListener { result.success(mapOf("phase" to "unknown")) }
    }

    private fun start(result: MethodChannel.Result) {
        val info = lastInfo
        if (info == null || pendingStart != null) {
            result.success(false)
            return
        }
        pendingStart = result
        val started = try {
            updates.startUpdateFlowForResult(info, askUpdate, AppUpdateOptions.defaultOptions(AppUpdateType.FLEXIBLE))
        } catch (e: Exception) {
            false
        }
        if (!started) {
            pendingStart = null
            result.success(false)
        }
    }

    private fun phaseOf(status: Int): String = when (status) {
        InstallStatus.PENDING, InstallStatus.DOWNLOADING -> "downloading"
        InstallStatus.DOWNLOADED -> "downloaded"
        InstallStatus.INSTALLING, InstallStatus.INSTALLED -> "latest"
        InstallStatus.FAILED, InstallStatus.CANCELED -> "failed"
        else -> "unknown"
    }
}
