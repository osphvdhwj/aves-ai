package deckers.thibault.aves.channel.calls

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Bundle
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
import java.util.concurrent.atomic.AtomicLong

class AiHandler(private val context: Context) : MethodChannel.MethodCallHandler {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val requestCounter = AtomicLong(0)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "health" -> health(result)
            "chat" -> chat(call, result)
            "gphotosBackupStatus" -> gphotosBackupStatus(call, result)
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

    private fun chat(call: MethodCall, result: MethodChannel.Result) {
        val text = call.argument<String>("text") ?: ""
        val entryIds = call.argument<List<Int>>("entryIds") ?: emptyList()
        @Suppress("UNCHECKED_CAST")
        val entries = call.argument<List<Map<String, Any?>>>("entries") ?: emptyList()
        if (text.isBlank()) {
            result.error("chat-empty", "empty text", null)
            return
        }
        scope.launch {
            val companionPackage = findInstalledCompanionPackage()
            if (companionPackage == null) {
                withContext(Dispatchers.Main) {
                    result.error("chat-no-companion", "companion not installed", null)
                }
                return@launch
            }

            val binder = bindWithTimeout(companionPackage, BIND_TIMEOUT_MS)
            if (binder == null) {
                withContext(Dispatchers.Main) {
                    result.error("chat-bind-timeout", "companion bind timeout", null)
                }
                return@launch
            }

            val response = CompletableDeferred<Map<String, Any?>>()
            val requestId = requestCounter.incrementAndGet()

            val callback = object : io.github.osphvdhwj.aves.ai.IAvesAiCallback.Stub() {
                override fun onProgress(id: Long, percent: Int) {
                    // no streaming in v1
                }

                override fun onResult(id: Long, bundle: Bundle?) {
                    val out = mutableMapOf<String, Any?>()
                    out["requestId"] = id
                    if (bundle != null) {
                        for (key in bundle.keySet()) {
                            out[key] = bundle.get(key)
                        }
                    }
                    response.complete(out)
                }

                override fun onError(id: Long, code: Int, message: String?) {
                    response.complete(mapOf(
                        "requestId" to id,
                        "errorCode" to code,
                        "errorMessage" to (message ?: ""),
                    ))
                }
            }

            try {
                val svc = io.github.osphvdhwj.aves.ai.IAvesAi.Stub.asInterface(binder)
                val req = Bundle().apply {
                    putString("capability", CAP_CHAT)
                    putLong("requestId", requestId)
                    putString("text", text)
                    putIntArray("entryIds", entryIds.toIntArray())
                    putParcelableArray("entries", entries.map(::mapToBundle).toTypedArray())
                }
                svc.submit(req, callback)
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("chat-submit-failed", e.message, null)
                }
                try { context.unbindService(lastConnection) } catch (_: Exception) {}
                return@launch
            }

            val reply = withTimeoutOrNull(CHAT_TIMEOUT_MS) { response.await() }
            try { context.unbindService(lastConnection) } catch (_: Exception) {}

            if (reply == null) {
                withContext(Dispatchers.Main) {
                    result.error("chat-timeout", "companion did not reply in time", null)
                }
            } else {
                withContext(Dispatchers.Main) { result.success(reply) }
            }
        }
    }

    private fun gphotosBackupStatus(call: MethodCall, result: MethodChannel.Result) {
        // Google Photos' media_store_id is a 64-bit value. Dart ints are
        // 64-bit; the platform channel may deliver them as Integer (fits
        // in 32 bits) or Long. Accept either via Number.
        val rawIds = call.argument<List<Any?>>("mediaStoreIds") ?: emptyList()
        val ids = LongArray(rawIds.size) { i ->
            when (val v = rawIds[i]) {
                is Number -> v.toLong()
                is String -> v.toLongOrNull() ?: -1L
                else -> -1L
            }
        }
        if (ids.isEmpty()) {
            withMain { result.success(mapOf("statuses" to emptyMap<String, String>())) }
            return
        }

        scope.launch {
            val companionPackage = findInstalledCompanionPackage()
            if (companionPackage == null) {
                withMain { result.success(mapOf("statuses" to emptyMap<String, String>(), "error" to "no companion")) }
                return@launch
            }

            val binder = bindWithTimeout(companionPackage, BIND_TIMEOUT_MS)
            if (binder == null) {
                withMain { result.success(mapOf("statuses" to emptyMap<String, String>(), "error" to "bind timeout")) }
                return@launch
            }

            val response = CompletableDeferred<Map<String, Any?>>()
            val requestId = requestCounter.incrementAndGet()

            val callback = object : io.github.osphvdhwj.aves.ai.IAvesAiCallback.Stub() {
                override fun onProgress(id: Long, percent: Int) {}
                override fun onResult(id: Long, bundle: Bundle?) {
                    val out = mutableMapOf<String, Any?>()
                    if (bundle != null) {
                        for (key in bundle.keySet()) {
                            val value = bundle.get(key)
                            // statuses come across as a Bundle; convert to Map<String,String>
                            if (key == "statuses" && value is Bundle) {
                                val map = mutableMapOf<String, String>()
                                for (k in value.keySet()) {
                                    val v = value.getString(k)
                                    if (v != null) map[k] = v
                                }
                                out["statuses"] = map
                            } else {
                                out[key] = value
                            }
                        }
                    }
                    response.complete(out)
                }
                override fun onError(id: Long, code: Int, message: String?) {
                    response.complete(mapOf(
                        "statuses" to emptyMap<String, String>(),
                        "errorCode" to code,
                        "errorMessage" to (message ?: ""),
                    ))
                }
            }

            try {
                val svc = io.github.osphvdhwj.aves.ai.IAvesAi.Stub.asInterface(binder)
                val req = Bundle().apply {
                    putString("capability", CAP_GPHOTOS)
                    putLong("requestId", requestId)
                    putLongArray("mediaStoreIds", ids)
                }
                svc.submit(req, callback)
            } catch (e: Exception) {
                withMain { result.success(mapOf("statuses" to emptyMap<String, String>(), "error" to (e.message ?: "submit failed"))) }
                try { context.unbindService(lastConnection) } catch (_: Exception) {}
                return@launch
            }

            val reply = withTimeoutOrNull(GPHOTOS_TIMEOUT_MS) { response.await() }
            try { context.unbindService(lastConnection) } catch (_: Exception) {}

            val safeReply = reply ?: mapOf("statuses" to emptyMap<String, String>(), "error" to "timeout")
            withMain { result.success(safeReply) }
        }
    }

    private suspend fun withMain(block: () -> Unit) = withContext(Dispatchers.Main) { block() }

    /// Converts a Dart map into a Bundle the companion can read.
    /// Only JSON-ish primitives are supported — anything else stringifies.
    private fun mapToBundle(m: Map<String, Any?>): Bundle = Bundle().apply {
        for ((k, v) in m) {
            when (v) {
                null -> {}
                is String -> putString(k, v)
                is Int -> putInt(k, v)
                is Long -> putLong(k, v)
                is Boolean -> putBoolean(k, v)
                is Double -> putDouble(k, v)
                is Float -> putFloat(k, v)
                else -> putString(k, v.toString())
            }
        }
    }

    private fun findInstalledCompanionPackage(): String? {
        for (pkg in COMPANION_PACKAGES) {
            try {
                @Suppress("DEPRECATION")
                context.packageManager.getPackageInfo(pkg, 0)
                return pkg
            } catch (_: Exception) {
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
        const val CAP_CHAT = "chat"
        const val CAP_GPHOTOS = "gphotos_backup"
        val COMPANION_PACKAGES = listOf(
            "com.avesplus.tools",
            "io.github.osphvdhwj.aves.ai.debug",
            "io.github.osphvdhwj.aves.ai",
        )
        const val COMPANION_SERVICE = "io.github.osphvdhwj.aves.ai.AiCompanionService"
        const val BIND_TIMEOUT_MS = 3000L
        const val CHAT_TIMEOUT_MS = 30000L
        const val GPHOTOS_TIMEOUT_MS = 20000L
    }
}
