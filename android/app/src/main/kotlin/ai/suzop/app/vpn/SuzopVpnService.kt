package ai.suzop.app.vpn

import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor

/**
 * Системный VPN-сервис. Создаёт tun-интерфейс и держит ядро
 * (libcore/Xray/sing-box/WireGuard) подключённым к выбранному серверу.
 *
 * Roadmap интеграции ядра (функционал как в Happ/Shadowrocket):
 *  - добавить .aar ядра в android/app/libs;
 *  - в startTunnel(): parseConfig(link) ядра -> proxy start -> protect(fd);
 *  - split tunneling: addApplication/addDisallowApplication;
 *  - kill switch: блокировать трафик при обрыве туннеля;
 *  - статистика: читать counters ядра каждую секунду (speed/total).
 */
class SuzopVpnService : VpnService() {
    private var tun: ParcelFileDescriptor? = null
    private var running = false

    companion object {
        private var instance: SuzopVpnService? = null
        fun get(): SuzopVpnService? = instance
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    override fun onDestroy() {
        instance = null
        stopTunnel()
        super.onDestroy()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // TODO: foreground-нотификация (обязательна для Android 14+)
        return START_STICKY
    }

    /** Поднимает tun-интерфейс. */
    fun startTunnel(config: Map<String, Any>): Boolean {
        if (running) return true
        try {
            val builder = Builder()
                .setSession("suzop")
                .addAddress("172.19.0.1", 24)
                .addDnsServer("1.1.1.1")
                .setMtu(8500)
            tun = builder.establish() ?: return false
            running = true
            // TODO: передать tun.fd ядру (libcore) + protect() сокетов ядра
            return true
        } catch (e: Exception) {
            return false
        }
    }

    fun stopTunnel() {
        running = false
        tun?.close()
        tun = null
    }

    val isRunning: Boolean get() = running

    /** Статистика туннеля (заполняется ядром). */
    fun stats(): Map<String, Any> = mapOf(
        "speedMbps" to 0.0,
        "totalMb" to 0.0
    )
}
