package deckers.thibault.aves.channel.calls

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import android.util.Log
import deckers.thibault.aves.utils.LogUtils
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull

class AiHandler(private val context: Context) : MethodChannel.MethodCallHandler {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "health" -> health(result)
            else -> result.notImplemented()
        }
    }

    private fun health(result: MethodChannel.Result) {
        scope.launch {
            val out = mutableMapOf<String, Any?>()

            val companionPackage = findInstalledCompanionPackage()
            out["companionPackage"] = companionPackage
            val installed = companionPackage != null
            out["installed"] = installed
            if (!installed) {
                out["connected"] = false
                withContext(Dispatchers.Main) { result.success(out) }
                return@launch
            }

            val binder = bindWithTimeout(companionPackage!!, BIND_TIMEOUT_MS)
            if (binder == null) {
                out["connected"] = false
                withContext(Dispatchers.Main) { result.success(out) }
                return@launch
            }

            try {
                val svc = io.github.osphvdhwj.aves.ai.IAvesAi.Stub.asInterface(binder)
                out["connected"] = true
                out["apiVersion"] = svc.apiVersion
                out["capabilities"] = svc.capabilities
                Log.i(LOG_TAG, "companion connected apiVersion=${svc.apiVersion} caps=${svc.capabilities}")
            } catch (e: Exception) {
                out["connected"] = false
                out["error"] = e.message
                Log.w(LOG_TAG, "companion query failed", e)
            } finally {
                try { context.unbindService(lastConnection) } catch (_: Exception) {}
            }

            withContext(Dispatchers.Main) { result.success(out) }
        }
    }

    private fun findInstalledCompanionPackage(): String? {
        for (pkg in COMPANION_PACKAGES) {
            try {
                @Suppress("DEPRECATION")
                context.packageManager.getPackageInfo(pkg, 0)
                return pkg
            } catch (_: Exception) {
                // not this one
            }
        }
        return null
    }

    @Volatile
    private var lastConnection: ServiceConnection = NoopConnection

    private suspend fun bindWithTimeout(companionPackage: String, timeoutMs: Long): IBinder? {
        val deferred = CompletableDeferred<IBinder>()
        val conn = object : ServiceConnection {
            override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
                if (service != null) deferred.complete(service)
            }
            override fun onServiceDisconnected(name: ComponentName?) {}
        }
        lastConnection = conn

        val intent = Intent().apply {
            setComponent(ComponentName(companionPackage, COMPANION_SERVICE))
        }

        val ok = try {
            context.bindService(intent, conn, Context.BIND_AUTO_CREATE)
        } catch (e: Exception) {
            Log.w(LOG_TAG, "bindService threw", e)
            false
        }
        if (!ok) return null

        val binder = withTimeoutOrNull(timeoutMs) { deferred.await() }
        if (binder == null) {
            try { context.unbindService(conn) } catch (_: Exception) {}
        }
        return binder
    }

    private object NoopConnection : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {}
        override fun onServiceDisconnected(name: ComponentName?) {}
    }

    companion object {
        private val LOG_TAG = LogUtils.createTag<AiHandler>()
        const val CHANNEL = "deckers.thibault/aves/ai"
        val COMPANION_PACKAGES = listOf(
            "io.github.osphvdhwj.aves.ai.debug",
            "io.github.osphvdhwj.aves.ai",
        )
        const val COMPANION_SERVICE = "io.github.osphvdhwj.aves.ai.AiCompanionService"
        const val BIND_TIMEOUT_MS = 3000L
    }
}
