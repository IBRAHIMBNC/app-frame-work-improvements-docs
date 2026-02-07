package de.symblcrowd.sc_appframework.broadcast

import android.content.Context
import android.content.Intent
import android.widget.Toast
import org.json.JSONObject

class ScBroadcastSender {
    companion object{
        fun sendCustomBroadcast(context: Context, action: String, args: JSONObject) {
            val intent = Intent(action)
            for (key in args.keys()) {
                when (val value = args.get(key)) {
                    is Int -> intent.putExtra(key, value)
                    is String -> intent.putExtra(key, value)
                    is Double -> intent.putExtra(key, value)
                    is Float -> intent.putExtra(key, value)
                    is Short -> intent.putExtra(key, value)
                    is Long -> intent.putExtra(key, value)
                    is Byte -> intent.putExtra(key, value)
                    is Boolean -> intent.putExtra(key, value)
                    is Char -> intent.putExtra(key, value)
                }
            }
            context.sendBroadcast(intent)
        }
    }
}