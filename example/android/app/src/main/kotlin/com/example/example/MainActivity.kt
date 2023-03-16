package com.example.example

import android.app.Activity
import android.app.Application.ActivityLifecycleCallbacks
import android.os.Bundle
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
                    application.registerActivityLifecycleCallbacks(AppLifecycleObserver(neotechServerHandler))
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
                    val res = HashMap<String, Any>()
                    val data = mutableListOf<HashMap<String, Any>>()
                    val userList = neotechServerHandler.userList
                    for (user in userList) {
                        val userMap = HashMap<String, Any>()
                        userMap["nickname"] = user
                        userMap["isAudioOn"] = neotechServerHandler.getPermissionAudio(user)
                        userMap["isDocOn"] = neotechServerHandler.getPermissionDoc(user)
                        data.add(userMap)
                    }
                    val gson = Gson()
                    val stringified = gson.toJson(data)
                    res["data"] = stringified
                    result.success(res)
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
                //초기화 결과
                val result = HashMap<String, Any>()
                if (msg.arg1 == EmeetplusApi.IELServerHandler.EL_RESULT_OK) {
                    result["type"] = SERVER_EVENT_CODE
                    result["data"] = "초기화 성공"
                    eventSink.success(result)
                } else {
                    eventSink.error("Server: 초기화 실패", null, null)
                }

            }
            EmeetplusApi.IELServerHandler.EL_MSG_LOGIN -> {
                // 로그인 결과
                if (msg.arg1 == EmeetplusApi.IELServerHandler.EL_RESULT_OK) {
                    val result = HashMap<String, Any>()
                    result["type"] = SERVER_EVENT_CODE
                    result["data"] = msg.obj.toString() + " 로그인 성공"
                    eventSink.success(result)


                } else {
                    eventSink.error("Server: 로그인 실패", null, null)
                }
           }
            EmeetplusApi.IELServerHandler.EL_MSG_ENTER_ROOM -> {
                // 방입장 결과
                if (msg.arg1 == EmeetplusApi.IELServerHandler.EL_RESULT_OK) {
                    //강의실 입장 성공
                    val result = HashMap<String, Any>()
                    result["type"] = SERVER_EVENT_CODE
                    result["data"] = msg.obj.toString() + "방입장 성공"
                    eventSink.success(result)

                } else {
                    //강의실 입장 실패
eventSink.error("Server: 방입장 실패", null, null)
                }
            }
            EmeetplusApi.IELServerHandler.EL_MSG_REMOTE_ENTER_ROOM -> {
                //상대편 방입장 이벤트
                
                val result = HashMap<String, Any>()
                val data = HashMap<String, Any>()
                result["type"] = USER_CODE
                data["isEnter"] = true
                data["nickname"]=msg.obj.toString()
                data["isAudioOn"] = serverHandler.getPermissionAudio(msg.obj.toString())
                data["isDocOn"] = serverHandler.getPermissionDoc(msg.obj.toString())
                val gson = Gson()
                val json = gson.toJson(data)
                result["data"] = json
                onUserEntered()

                eventSink.success(result)
            }
            EmeetplusApi.IELServerHandler.EL_MSG_REMOTE_EXIT_ROOM -> {
                //상대편 방퇴장 이벤트
                val result = HashMap<String, Any>()
                val data = HashMap<String, Any>()
                result["type"] = USER_CODE
                data["isEnter"] = false
                data["nickname"]=msg.obj.toString()
                val gson = Gson()
                val json = gson.toJson(data)
                result["data"] = json
                eventSink.success(result)
            }
            EmeetplusApi.IELServerHandler.EL_MSG_OVERLAPPED_USER_ID -> {
                //다른 사용자가 동일한 내아이디로 로그인 함
            }
            EmeetplusApi.IELServerHandler.EL_MSG_PERMISSION_CHANGE -> {
                //사용자권한(오디오권한, 문서권한) 변경 이벤트
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
                //서버와의 연결종료
                val result = HashMap<String, Any>()
                result["type"] = SERVER_EVENT_CODE
                result["data"] = "terminated"
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

class AppLifecycleObserver(private val serverHandler: ELServerHandler,) : ActivityLifecycleCallbacks {

    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
        TODO("Not yet implemented")
    }

    override fun onActivityStarted(activity: Activity) {
        TODO("Not yet implemented")
    }

    override fun onActivityResumed(activity: Activity) {
        TODO("Not yet implemented")
    }

    override fun onActivityPaused(activity: Activity) {
        TODO("Not yet implemented")
    }

    override fun onActivityStopped(activity: Activity) {
        TODO("Not yet implemented")
    }

    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {
        TODO("Not yet implemented")
    }

    override fun onActivityDestroyed(activity: Activity) {
        serverHandler.logout()
    }
}