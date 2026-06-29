package com.example.birren

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.provider.Telephony
import androidx.core.content.ContextCompat

class SmsMethodCallHandler(private val context: Context) {

    fun getLatestSms(sender: String?): Map<String, Any?>? {
        ensureReadSmsPermission()

        val projection = arrayOf(
            Telephony.Sms.ADDRESS,
            Telephony.Sms.BODY,
            Telephony.Sms.DATE,
        )

        val selection = if (sender != null) "${Telephony.Sms.ADDRESS} = ?" else null
        val selectionArgs = if (sender != null) arrayOf(sender) else null
        val sortOrder = "${Telephony.Sms.DATE} DESC LIMIT 1"

        context.contentResolver.query(
            Telephony.Sms.Inbox.CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            sortOrder,
        )?.use { cursor ->
            if (!cursor.moveToFirst()) {
                return null
            }
            return cursorToMap(cursor)
        }

        return null
    }

    fun getSmsByDateRange(
        startDate: Long,
        endDate: Long,
        sender: String?,
        limit: Int,
        offset: Int,
    ): List<Map<String, Any?>> {
        ensureReadSmsPermission()

        val projection = arrayOf(
            Telephony.Sms.ADDRESS,
            Telephony.Sms.BODY,
            Telephony.Sms.DATE,
        )

        val selection: String
        val selectionArgs: Array<String>

        if (sender != null) {
            selection =
                "${Telephony.Sms.ADDRESS} = ? AND ${Telephony.Sms.DATE} >= ? AND ${Telephony.Sms.DATE} <= ?"
            selectionArgs = arrayOf(sender, startDate.toString(), endDate.toString())
        } else {
            selection = "${Telephony.Sms.DATE} >= ? AND ${Telephony.Sms.DATE} <= ?"
            selectionArgs = arrayOf(startDate.toString(), endDate.toString())
        }

        val sortOrder = "${Telephony.Sms.DATE} DESC LIMIT $limit OFFSET $offset"
        val messages = mutableListOf<Map<String, Any?>>()

        context.contentResolver.query(
            Telephony.Sms.Inbox.CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            sortOrder,
        )?.use { cursor ->
            val addressIndex = cursor.getColumnIndexOrThrow(Telephony.Sms.ADDRESS)
            val bodyIndex = cursor.getColumnIndexOrThrow(Telephony.Sms.BODY)
            val dateIndex = cursor.getColumnIndexOrThrow(Telephony.Sms.DATE)

            while (cursor.moveToNext()) {
                messages.add(
                    mapOf(
                        "address" to cursor.getString(addressIndex),
                        "body" to cursor.getString(bodyIndex),
                        "date" to cursor.getLong(dateIndex),
                    ),
                )
            }
        }

        return messages
    }

    private fun cursorToMap(cursor: android.database.Cursor): Map<String, Any?> {
        val addressIndex = cursor.getColumnIndexOrThrow(Telephony.Sms.ADDRESS)
        val bodyIndex = cursor.getColumnIndexOrThrow(Telephony.Sms.BODY)
        val dateIndex = cursor.getColumnIndexOrThrow(Telephony.Sms.DATE)

        return mapOf(
            "address" to cursor.getString(addressIndex),
            "body" to cursor.getString(bodyIndex),
            "date" to cursor.getLong(dateIndex),
        )
    }

    private fun ensureReadSmsPermission() {
        val granted = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.READ_SMS,
        ) == PackageManager.PERMISSION_GRANTED

        if (!granted) {
            throw SecurityException("READ_SMS permission not granted")
        }
    }
}
