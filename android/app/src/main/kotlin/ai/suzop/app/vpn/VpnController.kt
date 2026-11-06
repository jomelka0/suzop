package ai.suzop.app.vpn

import android.content.Context
import java.util.concurrent.atomic.AtomicReference

/**
 * Управляет VPN-туннелем: стартует SuzopVpnService с конфигом сервера.
 *
 * Roadmap до рабочего подключения:
 * 1. Положить в android/app/libs ядро: libcore (Xray/sing-box) .aar или
 *    wireguard-android.
 * 2. В SuzopVpnService.startTunnel: поднять VpnService.Builder (tun),
 *    передать fd ядру, ядро поднимает VLESS/VMess/Trojan/SS/WG прокси.
 * 3. readStats() читать из ядра (traffic_up/down API ядра).
 */
class VpnController(private val context: Context) {
    private val currentConfig = AtomicReference<Map<String, Any>?>(null)

    fun start(config: Map<String, Any>): Boolean {
        currentConfig.set(config)
        val service = SuzopVpnService.get()
        return service?.startTunnel(config) ?: false
    }

    fun stop() {
        SuzopVpnService.get()?.stopTunnel()
    }

    fun isConnected(): Boolean = SuzopVpnService.get()?.isRunning == true

    fun readStats(): Map<String, Any> =
        SuzopVpnService.get()?.stats()
            ?: mapOf("speedMbps" to 0.0, "totalMb" to 0.0)
}
