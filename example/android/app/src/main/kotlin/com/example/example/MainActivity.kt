package com.example.example
import android.os.Handler
import android.os.Looper
import android.os.Message
import com.google.gson.Gson
import com.neo.api.EmeetplusApi
import com.neo.api.EmeetplusApi.IELServerHandler.OnFileTransferListener
import com.neo.net.ELServerHandler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugins.GeneratedPluginRegistrant
import org.json.JSONObject
import java.nio.ByteBuffer

const val FILE_CODE = 100

const val DRAWING_CODE = 200

const val CHAT_MESSAGE_CODE = 300

const val SERVER_EVENT_CODE = 400

const val VIEWPORT_CODE = 500

const val USER_CODE = 600

const val PERMISSION_CODE = 700

const val CID = "agcoding"

class MainActivity : FlutterActivity(), MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {
    companion object {
        const val METHOD_CHANNEL = "mathtutor_neotech_plugin"
        const val EVENT_CHANNEL = "mathtutor_neotech_plugin_event"
    }

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var neotechServerHandler: ELServerHandler
    private lateinit var id: String
    var holdingFilePath: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL
        )
        methodChannel.setMethodCallHandler(this)
        eventChannel = EventChannel(flutterEngine.dartExecutor, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)

    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                try {
                    holdingFilePath = call.argument("preloadImage")
                    neotechServerHandler = ELServerHandler()
                    neotechServerHandler.initial(this)
                    neotechServerHandler.setDownloadDir(getDownloadDir())
                    neotechServerHandler.setServerInfo(
                        call.argument("host"), call.argument("port")!!
                    )
                    result.success("Successfully Initialized")
                } catch (e: Exception) {
                    result.error("Failed to Initialize", e.message, e)
                }
            }
            "login" -> {
                try {
                    val userId: String = call.argument("userID")!!
                    val nickname: String = call.argument("nickname")!!
                    val ownerId: String = call.argument("ownerID")!!
                    neotechServerHandler.login(userId, nickname, ownerId, CID)
                    id = userId
                    result.success("Successfully Logged in")
                } catch (e: Exception) {
                    result.error("Failed to log in", e.message, e)
                }
            }
            "logout" -> {
                try {
                    neotechServerHandler.logout()
                    result.success("Successfully Logged out")
                } catch (e: Exception) {
                    result.error("Failed to log out", e.message, e)
                }
            }

            "sendPacket" -> {
                try {
                    val type: Int = call.argument("type")!!
                    val data: HashMap<String, Any> = call.argument("data")!!
                    val gson = Gson()
                    val stringified = gson.toJson(data)
                    neotechServerHandler.sendPacket(
                        type, ByteBuffer.wrap(stringified.toByteArray())
                    )
                    result.success("Packet Sent")
                } catch (e: Exception) {
                    result.error("Failed to send packet", e.message, e)
                }
            }
            "getUserList" -> {
                try {
                    val userList = neotechServerHandler.userList
                    result.success(userList)
                } catch (e: Exception) {
                    result.error("Failed to get user list ", e.message, e)
                }
            }
            "changePermissionAudio" -> {
                try {
                    val userId: String = call.argument("userID")!!
                    neotechServerHandler.changePermissionAudio(userId)
                    result.success("Successfully changed audio permission: userID: $userId")
                } catch (e: Exception) {
                    result.error("Failed to change audio permission", e.message, e)
                }
            }
            "getPermissionAudio" -> {
                try {
                    val userId: String = call.argument("userID")!!
                    result.success(neotechServerHandler.getPermissionAudio(userId))
                } catch (e: Exception) {
                    result.error("Failed to get audio permission", e.message, e)
                }
            }
            "changePermissinoDoc" -> {
                try {
                    val userId: String = call.argument("userID")!!
                    neotechServerHandler.changePermissionDoc(userId)
                    result.success("Successfully changed doc permission: userID: $userId")
                } catch (e: Exception) {
                    result.error("Failed to change doc permission", e.message, e)
                }
            }
            "getPermissionDoc" -> {
                try {
                    val userId: String = call.argument("userID")!!
                    result.success(neotechServerHandler.getPermissionDoc(userId))
                } catch (e: Exception) {
                    result.error("Failed to get doc permission", e.message, e)
                }
            }
            "turnOnMicrophone" -> {
                try {
                    val on: Boolean = call.argument("on")!!
                    neotechServerHandler.speakerphoneOn = on
                    result.success("Successfully ${if (on) "turned on" else "turned off"}")
                } catch (e: Exception) {
                    result.error("Failed to change the microphone setting", e.message, e)
                }
            }
            "isMicrophoneOn" -> {
                try {
                    result.success(neotechServerHandler.speakerphoneOn)
                } catch (e: Exception) {
                    result.error("Failed to get microphone setting", e.message, e)
                }
            }
            "sendImage" -> {
                try {
                    holdingFilePath = call.argument("filePath")!!
                    sendImage()

                    result.success("Successfully sent file")
                } catch (e: Exception) {
                    result.error("Failed to send file", e.message, e)
                }

            }


        }

    }

    private fun sendImage(
    ) {
        if (holdingFilePath != null) {
            neotechServerHandler.uploadFile(holdingFilePath)
        }

    }


    private fun getDownloadDir(): String {
        return cacheDir.absolutePath + "/live_downloaded_image"
    }

    override fun onListen(arguments: Any?, events: EventSink?) {
        if (events != null) {
            neotechServerHandler.setEventHandler(
                NeotechServerHandler(events, neotechServerHandler, id, onUserEntered = {
                    sendImage()
                })
            )
            neotechServerHandler.setOnFileTransferListener(
                OnFileTransferListenerImpl(
                    methodChannel, events
                )
            )

            neotechServerHandler.setOnPacketListener { i: Int, byteBuffer: ByteBuffer ->
                run {
                    val stringified = String(byteBuffer.array())
                    val jsono = JSONObject(stringified)
                    val map = HashMap<String, Any>()
                    for (key in jsono.keys()) {
                        map[key] = jsono[key]
                    }
                    events.success(map)
                }
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        neotechServerHandler.setEventHandler(null)
        neotechServerHandler.setOnFileTransferListener(null)
        neotechServerHandler.setOnPacketListener(null)
    }
}

class NeotechServerHandler(
    private val eventSink: EventSink,
    private val serverHandler: ELServerHandler,
    private val id: String,
    private val onUserEntered: () -> Unit

) : Handler(Looper.getMainLooper()) {

    override fun handleMessage(msg: Message) {
        when (msg.what) {
            EmeetplusApi.IELServerHandler.EL_MSG_REGISTRATION -> {
                //????????? ??????
            }
            EmeetplusApi.IELServerHandler.EL_MSG_LOGIN -> {
                // ????????? ??????
            }
            EmeetplusApi.IELServerHandler.EL_MSG_ENTER_ROOM -> {
                // ????????? ??????
            }
            EmeetplusApi.IELServerHandler.EL_MSG_REMOTE_ENTER_ROOM -> {
                //????????? ????????? ?????????
                val result = HashMap<String, Any>()
                result["type"] = USER_CODE
                result["isEnter"] = true
                result["data"] = msg.obj.toString()
                onUserEntered()

                eventSink.success(result)
            }
            EmeetplusApi.IELServerHandler.EL_MSG_REMOTE_EXIT_ROOM -> {
                //????????? ????????? ?????????
                val result = HashMap<String, Any>()
                result["type"] = USER_CODE
                result["isEnter"] = false
                result["data"] = msg.obj.toString()
                eventSink.success(result)
            }
            EmeetplusApi.IELServerHandler.EL_MSG_OVERLAPPED_USER_ID -> {
                //?????? ???????????? ????????? ??????????????? ????????? ???
            }
            EmeetplusApi.IELServerHandler.EL_MSG_PERMISSION_CHANGE -> {
                //???????????????(???????????????, ????????????) ?????? ?????????
                val audioPermission = serverHandler.getPermissionAudio(id)
                val docPermission = serverHandler.getPermissionDoc(id)
                val result = HashMap<String, Any>()
                result["type"] = PERMISSION_CODE
                result["data"] = HashMap<String, Any>().apply {
                    put("mic", audioPermission)
                    put("drawing", docPermission)
                }
                eventSink.success(result)
            }
            EmeetplusApi.IELServerHandler.EL_MSG_DISCONNECTED_SERVER -> {
                //???????????? ????????????
                val result = HashMap<String, Any>()
                result["event"] = "terminated"
                eventSink.success(result)
            }
        }

        super.handleMessage(msg)
    }
}

class OnFileTransferListenerImpl(
    private val methodChannel: MethodChannel, private val eventSink: EventSink
) : OnFileTransferListener {
    override fun uploadCompleted(filePath: String?) {
        val result = HashMap<String, Any>()
        result["event"] = "fileUploaded"
        result["filePath"] = filePath ?: ""
        methodChannel.invokeMethod("onUploadComplete", result)
    }

    override fun uploadFailed(filePath: String?) {
        val result = HashMap<String, Any>()
        result["event"] = "fileUploadFailed"
        result["filePath"] = filePath ?: ""
        methodChannel.invokeMethod("onUploadFailed", result)
    }

    override fun downloadCompleted(senderID: String?, filePath: String?) {
        val result = HashMap<String, Any>()
        result["event"] = "fileDownloaded"
        result["senderID"] = senderID ?: ""
        result["type"] = FILE_CODE
        result["data"] = filePath ?: ""
        eventSink.success(result)
    }

    override fun downloadFailed(senderID: String?, filePath: String?) {
        val result = HashMap<String, Any>()
        result["event"] = "fileDownloadFailed"
        result["senderID"] = senderID ?: ""
        result["filePath"] = filePath ?: ""
        methodChannel.invokeMethod("onDownloadFailed", result)

    }

}