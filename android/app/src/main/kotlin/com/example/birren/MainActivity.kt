package com.example.birren

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {
    private val channelName = "com.myapp.sms"
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val handler = SmsMethodCallHandler(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getLatestSms" -> {
                        val sender = call.argument<String>("sender")
                        scope.launch {
                            try {
                                val sms = withContext(Dispatchers.IO) {
                                    handler.getLatestSms(sender)
                                }
                                result.success(sms)
                            } catch (e: SecurityException) {
                                result.error(
                                    "PERMISSION_DENIED",
                                    e.message,
                                    null,
                                )
                            } catch (e: Exception) {
                                result.error(
                                    "SMS_QUERY_FAILED",
                                    e.message,
                                    null,
                                )
                            }
                        }
                    }

                    "getSmsByDateRange" -> {
                        val startDate = call.argument<Number>("startDate")?.toLong()
                        val endDate = call.argument<Number>("endDate")?.toLong()
                        val sender = call.argument<String>("sender")
                        val limit = call.argument<Int>("limit") ?: 100
                        val offset = call.argument<Int>("offset") ?: 0

                        if (startDate == null || endDate == null) {
                            result.error(
                                "INVALID_ARGUMENT",
                                "startDate and endDate are required",
                                null,
                            )
                            return@setMethodCallHandler
                        }

                        scope.launch {
                            try {
                                val messages = withContext(Dispatchers.IO) {
                                    handler.getSmsByDateRange(
                                        startDate = startDate,
                                        endDate = endDate,
                                        sender = sender,
                                        limit = limit,
                                        offset = offset,
                                    )
                                }
                                result.success(messages)
                            } catch (e: SecurityException) {
                                result.error(
                                    "PERMISSION_DENIED",
                                    e.message,
                                    null,
                                )
                            } catch (e: Exception) {
                                result.error(
                                    "SMS_QUERY_FAILED",
                                    e.message,
                                    null,
                                )
                            }
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
