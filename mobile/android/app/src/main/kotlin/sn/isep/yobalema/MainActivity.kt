package sn.isep.yobalema

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Canal des notifications push (même identifiant que NotificationConfig.CANAL_ANDROID côté backend).
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val canal = NotificationChannel(
                "yobalema_notifications", "Réservations, messages et trajets", NotificationManager.IMPORTANCE_HIGH
            ).apply { description = "Notifications de l'application YOBALEMAsn" }
            getSystemService(NotificationManager::class.java).createNotificationChannel(canal)
        }
    }
}
