package id.smart.smart_mobile

import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Pembaruan dalam aplikasi: aplikasi membuktikan kunci penandatangannya sendiri dan memeriksa
        // kunci penandatangan APK unduhan sebelum diserahkan ke pemasang sistem.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "smart/app_info")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "signingCertSha256" -> result.success(certOf(installedInfo()))
                    "archiveCertSha256" -> {
                        val path = call.argument<String>("path")
                        result.success(if (path == null) null else certOf(archiveInfo(path)))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun installedInfo(): PackageInfo? = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
        }
    } catch (e: Exception) {
        null
    }

    private fun archiveInfo(path: String): PackageInfo? = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageManager.getPackageArchiveInfo(path, PackageManager.GET_SIGNING_CERTIFICATES)
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageArchiveInfo(path, PackageManager.GET_SIGNATURES)
        }
    } catch (e: Exception) {
        null
    }

    private fun certOf(info: PackageInfo?): String? {
        if (info == null) return null
        val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.signingInfo?.apkContentsSigners
        } else {
            @Suppress("DEPRECATION")
            info.signatures
        }
        return signatures?.firstOrNull()?.let { sig ->
            MessageDigest.getInstance("SHA-256").digest(sig.toByteArray())
                .joinToString("") { "%02x".format(it) }
        }
    }
}
