package com.tunnel.vpn

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.tunnel.vpn/core"
    private val VPN_REQUEST_CODE = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startVpn" -> {
                    val prepareIntent = VpnService.prepare(this)
                    if (prepareIntent != null) {
                        startActivityForResult(prepareIntent, VPN_REQUEST_CODE)
                    } else {
                        launchTunnelService()
                    }
                    result.success(true)
                }
                "stopVpn" -> {
                    val intent = Intent(this, TunnelVpnService::class.java).apply { action = "STOP" }
                    startService(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_REQUEST_CODE && resultCode == Activity.RESULT_OK) {
            launchTunnelService()
        }
    }

    private fun launchTunnelService() {
        val intent = Intent(this, TunnelVpnService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
}

