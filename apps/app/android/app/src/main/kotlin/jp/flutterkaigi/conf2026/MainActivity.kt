package jp.flutterkaigi.conf2026

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createAnnouncementsChannel()
    }

    // FCM が表示する通知の既定チャンネル(AndroidManifest.xml)。チャンネルが無いと既定の重要度の
    // 「その他」に入りヘッドアップ表示されない。作成済みでも名前と説明が更新されるだけなので毎回呼ぶ。
    private fun createAnnouncementsChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            getString(R.string.default_notification_channel_id),
            getString(R.string.notification_channel_name),
            NotificationManager.IMPORTANCE_HIGH,
        )
        channel.description = getString(R.string.notification_channel_description)
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }
}
