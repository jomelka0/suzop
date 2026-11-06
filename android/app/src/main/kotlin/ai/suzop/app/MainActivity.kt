package ai.suzop.app

import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import ai.suzop.app.vpn.VpnController

class MainActivity : FlutterActivity() {
    private val channel = "suzop/vpn"
    private val statsChannel = "suzop/stats"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val controller = VpnController(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "connect" -> {
                        val config = call.arguments<Map<String, Any>>()
                        // Запрашиваем системное разрешение VPN,
                        // если оно ещё не выдано
                        val ready = VpnService.prepare(this@MainActivity)
                        if (ready != null) {
                            result.success(false) // пользователь должен подтвердить
                        } else {
                            val ok = controller.start(config)
                            result.success(ok)
                        }
                    }
                    "disconnect" -> {
                        controller.stop()
                        result.success(true)
                    }
                    "status" -> result.success(mapOf(
                        "connected" to controller.isConnected()
                    ))
                    else -> result.notImplemented()
                }
            }

        // Поток статистики: скорость и объём данных от ядра
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, statsChannel)
            .setStreamHandler(object : EventChannel.StreamHandler {
                var ticker: java.util.Timer? = null
                override fun onListen(args: Any?, events: EventChannel.EventSink?) {
                    ticker = java.util.Timer().apply {
                        scheduleAtFixedRate(object : java.util.TimerTask() {
                            override fun run() {
                                val s = controller.readStats()
                                events?.success(s)
                            }
                        }, 0, 1000)
                    }
                }
                override fun onCancel(args: Any?) {
                    ticker?.cancel()
                    ticker = null
                }
            })
    }
}
