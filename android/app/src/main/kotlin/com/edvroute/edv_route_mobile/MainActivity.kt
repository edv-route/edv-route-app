package com.edvroute.edv_route_mobile

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts one native call: requesting background location BY ITSELF.
 *
 * It cannot be done through geolocator. Android is explicit about it:
 *
 *   "If you request a foreground location permission and the background
 *    location permission at the same time, the system ignores the request and
 *    doesn't grant your app either permission."
 *
 * geolocator builds its request from the manifest — which contains the
 * foreground permissions — and then appends ACCESS_BACKGROUND_LOCATION to that
 * same list, so the whole request is silently ignored and the driver sees
 * nothing happen. Asking for it alone is what makes Android 11+ open the
 * app's location settings page, which is where "Permitir todo el tiempo" lives.
 */
class MainActivity : FlutterActivity() {

    private val channelName = "edvroute/permissions"
    private val requestCode = 7311

    /** Answered when the system comes back with a result. */
    private var pending: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestBackgroundLocation" -> requestBackgroundLocation(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun requestBackgroundLocation(result: MethodChannel.Result) {
        // Before Android 10 there is no such permission: holding the foreground
        // one already covers background use.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.success(true)
            return
        }

        if (hasBackgroundPermission()) {
            result.success(true)
            return
        }

        // A second request while one is in flight would strand the first.
        if (pending != null) {
            result.success(false)
            return
        }

        pending = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION),
            requestCode,
        )
    }

    private fun hasBackgroundPermission(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.Q ||
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_BACKGROUND_LOCATION,
            ) == PackageManager.PERMISSION_GRANTED

    override fun onRequestPermissionsResult(
        code: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(code, permissions, grantResults)
        if (code != requestCode) return

        val reply = pending
        pending = null
        // Checked against the system rather than the callback's array: on
        // Android 11+ this returns while the user is still on the settings
        // page, so grantResults is routinely empty and means nothing.
        reply?.success(hasBackgroundPermission())
    }

    /**
     * The driver may grant it on the settings screen and come back, long after
     * onRequestPermissionsResult already answered. Re-checking here is what
     * lets the app notice.
     */
    override fun onResume() {
        super.onResume()
        val reply = pending ?: return
        if (hasBackgroundPermission()) {
            pending = null
            reply.success(true)
        }
    }
}
