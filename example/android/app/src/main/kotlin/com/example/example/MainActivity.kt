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
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import org.json.JSONArray
import org.json.JSONObject
import org.json.JSONTokener
import java.nio.ByteBuffer

const val FILE_CODE = 100

const val DRAWING_CODE = 200

const val CHAT_MESSAGE_CODE = 300

const val SERVER_EVENT_CODE = 400

const val VIEWPORT_CODE = 500

const val USER_CODE = 600

const val PERMISSION_CODE = 700

const val CID = "agcoding"

class MainActivity : FlutterActivity(), MethodChannel.MethodCallHandler{
    private var initResult: MethodChannel.Result? = null
    private var loginResult: MethodChannel.Result? = null
    private var sendFileResult: MethodChannel.Result? = null
    companion object {
        const val METHOD_CHANNEL = "mathtutor_neotech_plugin"
    }

    private lateinit var methodChannel: MethodChannel
    private lateinit var neotechServerHandler: ELServerHandler
    private lateinit var id: String
    var holdingFilePath: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL
        )
        methodChannel.setMethodCallHandler(this)
    }


    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                try {
                    initResult = result
                    neotechServerHandler = ELServerHandler()
                    id = call.argument("userID")!!
                    neotechServerHandler.setEventHandler(
                        NeotechServerHandler(methodChannel, neotechServerHandler, id, onUserEntered = {
                            sendImage()
                        },
                        onInitDone = {
                            initResult?.success(if(it) "Init Done" else "Init Failed")
                            initResult = null
                        },
                        onRoomEnteringDone = {
                            loginResult?.success(if(it) "Login Done" else "Login Failed")
                            loginResult = null
                        },
                        )
                    )
                    holdingFilePath = call.argument("preloadImage")
                    neotechServerHandler.setDownloadDir(getDownloadDir())
                    neotechServerHandler.setServerInfo(
                        call.argument("host"), call.argument("port")!!
                    )
                    neotechServerHandler.initial(this)


                    neotechServerHandler.setOnPacketListener { i: Int, byteBuffer: ByteBuffer ->
                        run {
                            val stringified = String(byteBuffer.array())
                            if (determineJsonType(stringified) is JSONObject) {
                                val jsono = JSONObject(stringified)
                                val map = HashMap<String, Any>()
                                for (key in jsono.keys()) {
                                    map[key] = jsono[key]
                                }
                                methodChannel.invokeMethod("eventSinkAlt",map)
                            } else if (determineJsonType(stringified) is JSONArray) {
                                val jsona = JSONArray(stringified)
                                for (i in 0 until jsona.length()) {
                                    val jsono = jsona.getJSONObject(i)
                                    val map = HashMap<String, Any>()
                                    for (key in jsono.keys()) {
                                        map[key] = jsono[key]
                                    }
                                    methodChannel.invokeMethod("eventSinkAlt",map)
                                }
                            }

                        }
                    }
                    neotechServerHandler.setOnFileTransferListener(
                        OnFileTransferListenerImpl(
                            methodChannel,
                            onFileSent = {
                                sendFileResult?.success(if (it) "File Sent" else "File Not Sent")
                                sendFileResult = null
                            }

                        )
                    )
                } catch (e: Exception) {
                    result.error("Failed to Initialize", e.message, e)
                }
            }
            "login" -> {
                try {
                    loginResult = result
                    val ownerId: String = call.argument("ownerID")!!
                    neotechServerHandler.login(id, id, ownerId, CID)
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
                    val data: ArrayList<HashMap<String, Any>> = call.argument("data")!!
                    val gson = Gson()
                    if (data.size == 1) {
                        val stringified = gson.toJson(data[0])
                        neotechServerHandler.sendPacket(
                            type, ByteBuffer.wrap(stringified.toByteArray())
                        )
                    } else {
                        val stringified = gson.toJson(data)
                        neotechServerHandler.sendPacket(
                            type, ByteBuffer.wrap(stringified.toByteArray())
                        )
                    }
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
                    for (userId in userList) {
                        val userMap = HashMap<String, Any>()
                        userMap["id"] = userId
                        userMap["isAudioOn"] = neotechServerHandler.getPermissionAudio(userId)
                        userMap["isDocOn"] = neotechServerHandler.getPermissionDoc(userId)
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
            "changePermissionDoc" -> {
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
                    sendFileResult = result
                    holdingFilePath = call.argument("filePath")!!
                    sendImage()
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

    fun determineJsonType(jsonString: String): Any? {
        return JSONTokener(jsonString).nextValue()
    }


}

class NeotechServerHandler(
    private val methodChannel: MethodChannel,
    private val serverHandler: ELServerHandler,
    private val id: String,
    private val onUserEntered: () -> Unit,
    private val onInitDone: (result:Boolean) -> Unit,
    private val onRoomEnteringDone: (result:Boolean) -> Unit

) : Handler(Looper.getMainLooper()) {

    override fun handleMessage(msg: Message) {
        when (msg.what) {
            EmeetplusApi.IELServerHandler.EL_MSG_REGISTRATION -> {
                //초기화 결과
                val result = HashMap<String, Any>()
                if (msg.arg1 == EmeetplusApi.IELServerHandler.EL_RESULT_OK) {
                    onInitDone(true)
                } else {
                    onInitDone(false)
                }
            }
            EmeetplusApi.IELServerHandler.EL_MSG_LOGIN -> {
                // 로그인 결과
                if (msg.arg1 == EmeetplusApi.IELServerHandler.EL_RESULT_OK) {
                    val result = HashMap<String, Any>()
                    result["type"] = SERVER_EVENT_CODE
                    result["data"] = msg.obj.toString() + " 로그인 성공"
                    this.methodChannel.invokeMethod("onServerEvent", result)
                } else {
                    val result = HashMap<String, Any>()
                    result["type"] = SERVER_EVENT_CODE
                    result["data"] = msg.obj.toString() + " 로그인 실패"
                    onRoomEnteringDone(false)
                }
            }
            EmeetplusApi.IELServerHandler.EL_MSG_ENTER_ROOM -> {
                // 방입장 결과
                if (msg.arg1 == EmeetplusApi.IELServerHandler.EL_RESULT_OK) {
                    //강의실 입장 성공
                    onRoomEnteringDone(true)

                } else {
                    //강의실 입장 실패
                    onRoomEnteringDone(false)
                }
            }
            EmeetplusApi.IELServerHandler.EL_MSG_REMOTE_ENTER_ROOM -> {
                //상대편 방입장 이벤트

                val result = HashMap<String, Any>()
                val data = HashMap<String, Any>()
                result["type"] = USER_CODE
                data["isEnter"] = true
                data["id"]=msg.obj.toString()
                data["isAudioOn"] = serverHandler.getPermissionAudio(msg.obj.toString())
                data["isDocOn"] = serverHandler.getPermissionDoc(msg.obj.toString())
                val gson = Gson()
                val json = gson.toJson(data)
                result["data"] = json
                onUserEntered()
                methodChannel.invokeMethod("eventSinkAlt", result)

            }
            EmeetplusApi.IELServerHandler.EL_MSG_REMOTE_EXIT_ROOM -> {
                //상대편 방퇴장 이벤트
                val result = HashMap<String, Any>()
                val data = HashMap<String, Any>()
                result["type"] = USER_CODE
                data["isEnter"] = false
                data["id"]=msg.obj.toString()
                val gson = Gson()
                val json = gson.toJson(data)
                result["data"] = json
                methodChannel.invokeMethod("eventSinkAlt", result)
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
                methodChannel.invokeMethod("eventSinkAlt", result)
            }
            EmeetplusApi.IELServerHandler.EL_MSG_DISCONNECTED_SERVER -> {
                //서버와의 연결종료
                val result = HashMap<String, Any>()
                result["type"] = SERVER_EVENT_CODE
                result["data"] = "terminated"
                this.methodChannel.invokeMethod("onServerEvent", result)
            }
        }

        super.handleMessage(msg)
    }
}

class OnFileTransferListenerImpl(
    private val methodChannel: MethodChannel,
    private val onFileSent: (result: Boolean) -> Unit
) : OnFileTransferListener {
    override fun uploadCompleted(filePath: String?) {
        val result = HashMap<String, Any>()
        result["event"] = "fileUploaded"
        result["filePath"] = filePath ?: ""
        onFileSent(true)
    }

    override fun uploadFailed(filePath: String?) {
        val result = HashMap<String, Any>()
        result["event"] = "fileUploadFailed"
        result["filePath"] = filePath ?: ""
        onFileSent(false)
    }

    override fun downloadCompleted(senderID: String?, filePath: String?) {
        val result = HashMap<String, Any>()
        result["event"] = "fileDownloaded"
        result["senderID"] = senderID ?: ""
        result["type"] = FILE_CODE
        result["data"] = filePath ?: ""
        methodChannel.invokeMethod("eventSinkAlt", result)
    }

    override fun downloadFailed(senderID: String?, filePath: String?) {
        val result = HashMap<String, Any>()
        result["event"] = "fileDownloadFailed"
        result["senderID"] = senderID ?: ""
        result["filePath"] = filePath ?: ""
        methodChannel.invokeMethod("onDownloadFailed", result)

    }

}