package ai.suzop.app

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import ai.suzop.app.vpn.VpnController

class MainActivity : FlutterActivity() {
    private val channel = "suzop/vpn"
    private val statsChannel = "suzop/stats"

    private val vpnPermissionRequest = 1001
    private var pendingConnect: Map<String, Any>? = null
    private var pendingResult: MethodChannel.Result? = null

    private lateinit var controller: VpnController
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        controller = VpnController(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "connect" -> {
                        val config = call.arguments<Map<String, Any>>() ?: mapOf()
                        // Запрашиваем системное разрешение VPN:
                        // если ещё не выдано — показываем диалог и
                        // продолжаем подключение после подтверждения.
                        val ready = VpnService.prepare(this@MainActivity)
                        if (ready != null) {
                            pendingConnect = config
                            pendingResult = result
                            @Suppress("DEPRECATION")
                            startActivityForResult(ready, vpnPermissionRequest)
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

        // Поток статистики: скорость и объём данных от ядра.
        // EventSink можно вызывать только из главного потока —
        // результаты таймера перебрасываются через Handler.
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, statsChannel)
            .setStreamHandler(object : EventChannel.StreamHandler {
                var ticker: java.util.Timer? = null
                override fun onListen(args: Any?, events: EventChannel.EventSink?) {
                    ticker = java.util.Timer().apply {
                        scheduleAtFixedRate(object : java.util.TimerTask() {
                            override fun run() {
                                val s = controller.readStats()
                                mainHandler.post {
                                    events?.success(s)
                                }
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

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == vpnPermissionRequest) {
            val config = pendingConnect
            val result = pendingResult
            pendingConnect = null
            pendingResult = null
            if (resultCode == Activity.RESULT_OK && config != null && result != null) {
                result.success(controller.start(config))
            } else {
                // Пользователь отклонил разрешение — подключения нет.
                result?.success(false)
            }
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}
