import UIKit
import Flutter
import EMPCLibEx

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate,ELServerHandlerDelegate {
    var methodChannel: FlutterMethodChannel!
    var neotechServerHandler: ELServerHandler!
    var id: String?
    var holdingFilePath: String?
    
    let FILE_CODE = 100
    let DRAWING_CODE = 200
    let CHAT_MESSAGE_CODE = 300
    let SERVER_EVENT_CODE = 400
    let VIEWPORT_CODE = 500
    let USER_CODE = 600
    let PERMISSION_CODE = 700
    let CID = "agcoding"
    var loginResult: FlutterResult?
    var sendFileResult: FlutterResult?

    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      let METHOLD_CHANNEL = "mathtutor_neotech_plugin";
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    methodChannel = FlutterMethodChannel(name: METHOLD_CHANNEL, binaryMessenger: controller.binaryMessenger)
      
    methodChannel.setMethodCallHandler(methodCallHandler)
      
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    func receivedPacket(_ type: Int32, buffer: UnsafePointer<CChar>, length: Int32) {
        let data = Data(bytes: buffer, count: Int(length))
        if let stringified = String(data: data, encoding: .utf8) {
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                print("JSON Object: \(jsonObject)")

                if let jsono = jsonObject as? [String: Any] {
                    var map = [String: Any]()
                    for (key, value) in jsono {
                        map[key] = value
                    }
                    methodChannel.invokeMethod("eventSinkAlt", arguments: map)
                } else {
                    if let jsonArrayO = jsonObject as? [NSDictionary] {
                        for obj in jsonArrayO {
                            var map = [String: Any]()
                            for (key, value) in obj {
                                map[key as! String] = value
                            }
                            methodChannel.invokeMethod("eventSinkAlt", arguments: map)
                        }
                    }
                }
            } catch {
                print("Error occurred: \(error)")
            }
        }
    }
    
    private func methodCallHandler(call:FlutterMethodCall, result:@escaping FlutterResult) -> Void{
        let args = call.arguments as? Dictionary<String, Any>
        switch call.method {
        case "initialize":
            self.neotechServerHandler = ELServerHandler.getInstance()
            self.neotechServerHandler.initial()
            self.neotechServerHandler.setEventDelegate(self)
            let host = args!["host"] as? String
            let port = args!["port"] as? Int32
            self.neotechServerHandler.setServerInfo(host!, serverPort: port!)
            result(true)
        case "login":
            self.loginResult = result
            self.id = args!["userID"] as? String ?? args!["nickname"] as? String
            let nickname:String? = args!["nickname"]! as? String
            let ownerId:String? = args!["ownerID"]! as? String
            self.neotechServerHandler.login(self.id!, alias: nickname!, ownerID: ownerId!, company: CID)
        case "logout":
            self.neotechServerHandler.logout()
            result("Successfully Logged out")
        case "sendPacket":
            do {
                guard let type = args!["type"] as? Int32,
                      let data = args!["data"] as? [[String: Any]] else {
                    throw NSError(domain: "Invalid arguments", code: -1, userInfo: nil)
                }

                let jsonData: Data
                if data.count == 1 {
                    jsonData = try JSONSerialization.data(withJSONObject: data[0], options: [])
                } else {
                    jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
                }

                let stringified = String(data: jsonData, encoding: .utf8) ?? ""
                self.neotechServerHandler.sendPacket(type, buffer: stringified, length: Int32(stringified.utf8.count))
                result("Packet Sent")
            } catch {
                result("Failed to send packet")
            }
        case "getUserList":
            do {
                    var res = [String: Any]()
                    var data = [UserData]()
                let userList = self.neotechServerHandler.getUserList() as! [String]
                    for userId in userList {
                        let user = UserData(
                            id: userId,
                            isAudioOn: self.neotechServerHandler.getPermissionAudio(userId),
                            isDocOn: self.neotechServerHandler.getPermissionDoc(userId)
                        )
                        data.append(user)
                    }
                    let jsonEncoder = JSONEncoder()
                    let jsonData = try jsonEncoder.encode(data)
                    if let stringified = String(data: jsonData, encoding: .utf8) {
                        res["data"] = stringified
                    }
                    return result(res)
                } catch {
                    return result("Failed to get user list")
                }
        case "changePermissionAudio":
            let userId = args!["userID"] as? String
            self.neotechServerHandler.changePermissionAudio(userId!)
            result("Successfully changed audio permission: userID: \(userId!)")
        case "getPermissionAudio":
            let userId = args!["userID"] as? String
            result(self.neotechServerHandler.getPermissionAudio(userId!))
        case "changePermissionDoc":
            let userId = args!["userID"] as? String
            self.neotechServerHandler.changePermissionDoc(userId!)
            result("Successfully changed doc permission: userID: \(userId!)")
        case "getPermissionDoc":
            let userId = args!["userID"] as? String
            result(self.neotechServerHandler.getPermissionDoc(userId!))
        case "turnOnMicrophone":
            let on = args!["on"] as? Bool
            self.neotechServerHandler.setSpeakerphoneOn(on!)
            result("Successfully \((on!) ? "turned on" : "turned off")")
        case "isMicrophoneOn":
            result(self.neotechServerHandler.getSpeakerphoneOn())
        case "sendImage":
            holdingFilePath = args!["filePath"] as? String
            sendFileResult = result
            if (self.holdingFilePath != nil){
                self.neotechServerHandler.uploadFile(self.holdingFilePath!)}
        default:
            break
        }
    }
    
    func onServerEvent(_ what:Int, arg1:Int, arg2: String) -> Void {
        switch what {
            case EL_MSG_LOGIN:
            if arg1 == EL_RESULT_OK {
                var result = [String: Any]()
                result["type"] = SERVER_EVENT_CODE
                result["data"] = "\(arg2) 로그인 성공"
                self.methodChannel.invokeMethod("onServerEvent", arguments: result)
            } else {
                self.loginResult!(false)
            }
                break
            case EL_MSG_ENTER_ROOM:
            if arg1 == EL_RESULT_OK{
                self.loginResult!(true)
            } else {
                self.loginResult!(false)
            }
                break
            case EL_MSG_REMOTE_ENTER_ROOM:
                // 상대편 방 입장 이벤트
                var result = [String: Any]()
                let data = RoomData(
                    isEnter: true,
                    id: arg2,
                    isAudioOn: self.neotechServerHandler.getPermissionAudio(arg2),
                    isDocOn: self.neotechServerHandler.getPermissionDoc(arg2)
                )
                let jsonEncoder = JSONEncoder()
                if let jsonData = try? jsonEncoder.encode(data) {
                    result["data"] = String(data: jsonData, encoding: .utf8)
                }
                result["type"] = USER_CODE
                if (self.holdingFilePath != nil) {
                    self.neotechServerHandler.uploadFile(self.holdingFilePath!)
                }
                methodChannel.invokeMethod("eventSinkAlt", arguments: result)
            
        case EL_MSG_REMOTE_EXIT_ROOM:
            // 상대편 방 퇴장 이벤트
            var result = [String: Any]()
                    let data = ExitRoomData(isEnter: false, id: arg2)
                    let jsonEncoder = JSONEncoder()
                    if let jsonData = try? jsonEncoder.encode(data) {
                        result["data"] = String(data: jsonData, encoding: .utf8)
                    }
                    result["type"] = USER_CODE
            methodChannel.invokeMethod("eventSinkAlt", arguments: result)
            
        case EL_MSG_OVERLAPPED_USER_ID:
            // 다른 사용자가 동일한 내 아이디로 로그인함
            break
            
        case EL_MSG_PERMISSION_CHANGE:
            // 사용자 권한 (오디오 권한, 문서 권한) 변경 이벤트
            let audioPermission = self.neotechServerHandler.getPermissionAudio(id!)
            let docPermission = self.neotechServerHandler.getPermissionDoc(id!)
            var result = [String: Any]()
            result["type"] = PERMISSION_CODE
            result["data"] = ["mic": audioPermission, "drawing": docPermission]
            methodChannel.invokeMethod("eventSinkAlt", arguments: result)
            
        case EL_MSG_DISCONNECTED_SERVER:
            // 서버와의 연결 종료
            var result = [String: Any]()
            result["type"] = SERVER_EVENT_CODE
            result["data"] = "terminated"
            self.methodChannel.invokeMethod("onServerEvent", arguments: result)
            default:
                break
        }
        
    }
    func uploadComplited(_ filePath: String) {
        self.sendFileResult!(true)
    }
    
    func uploadFailed(_ filePath: String) {
        self.sendFileResult!(false)
    }
    
    func downloadComplited(_ filePath: String) {
        var result = [String: Any]()
            result["event"] = "fileDownloaded"
            result["type"] = FILE_CODE
            result["data"] = filePath
            methodChannel.invokeMethod("eventSinkAlt", arguments: result)
    }
    
    func downloadFailed(_ filePath: String) {
        var result = [String: Any]()
            result["event"] = "fileDownloadFailed"
            result["filePath"] = filePath
            methodChannel.invokeMethod("onDownloadFailed", arguments: result)
    }
}

struct RoomData: Encodable {
    let isEnter: Bool
    let id: String
    let isAudioOn: Bool
    let isDocOn: Bool
}

struct ExitRoomData: Encodable {
    let isEnter: Bool
    let id: String
}

struct UserData: Encodable {
    let id: String
    let isAudioOn: Bool
    let isDocOn: Bool
}
