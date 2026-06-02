import Foundation
import Combine
import UIKit
import RGCxrClient
import RGCoreKit

@objcMembers
@objc(RokidCXRLBridge)
public final class RokidCXRLBridge: NSObject {
    private static let instance = RokidCXRLBridge()

    private let client: any RGCxrClient = CxrClient.shared
    private var cancellables = Set<AnyCancellable>()
    private var eventsBound = false
    private var initialized = false
    private var eventHandler: ((NSDictionary) -> Void)?
    private let defaultPackageName = "com.rokid.cxrswithcxrl"

    @objc public static func sharedInstance() -> RokidCXRLBridge {
        return instance
    }

    public func bindEventsIfNeeded() {
        guard !eventsBound else { return }
        eventsBound = true

        client.auth.eventPublisher
            .sink { [weak self] event in
                self?.emit(type: "auth", payload: self?.authEventPayload(event) ?? [:])
            }
            .store(in: &cancellables)

        client.audioEventPublisher
            .sink { [weak self] event in
                self?.emit(type: "audio", payload: self?.audioEventPayload(event) ?? [:])
            }
            .store(in: &cancellables)

        client.customViewRunningEventPublisher
            .sink { [weak self] event in
                self?.emit(type: "customViewRunning", payload: ["isRunning": event.isRunning])
            }
            .store(in: &cancellables)

        client.appResumeChangeEventPublisher
            .sink { [weak self] event in
                self?.emit(type: "appResumeChange", payload: ["packageName": event.packageName])
            }
            .store(in: &cancellables)

        client.notifyEventPublisher
            .sink { [weak self] event in
                self?.emit(type: "notify", payload: self?.notifyPayload(event) ?? [:])
            }
            .store(in: &cancellables)
    }

    public func initializeClient(_ options: NSDictionary, completion: @escaping (NSDictionary) -> Void) {
        bindEventsIfNeeded()
        configureAuthFromOptions(options["auth"] as? NSDictionary)

        let modeString = string(options["mode"]) ?? "customApp"
        let mode: RGCxrClientInitMode = modeString == "customView" ? .customView : .customApp
        let appDisplayName = string(options["appDisplayName"])
        let pageName = string(options["pageName"])
        let result = CxrClient.initialize(
            mode: mode,
            options: .init(appDisplayName: appDisplayName, pageName: pageName)
        )

        let outcome: String
        switch result {
        case .success:
            outcome = "success"
            initialized = true
        case .failureAlreadyInitialized:
            outcome = "failureAlreadyInitialized"
            initialized = true
        @unknown default:
            outcome = "unknown"
        }

        completion(ok(["outcome": outcome, "initialized": initialized]))
    }

    public func configureAuth(_ options: NSDictionary) -> NSDictionary {
        configureAuthFromOptions(options)
        return ok([:])
    }

    public func authenticate(_ options: NSDictionary, completion: @escaping (NSDictionary) -> Void) {
        let scopes = stringArray(options["scopes"]) ?? ["device_control", "audio_stream"]
        let bundleId = string(options["bundleId"])
        let appName = string(options["appName"])

        client.auth.authenticate(scopes: scopes, bundleId: bundleId, appName: appName) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    completion(self.ok([
                        "token": data.token,
                        "sessionId": data.sessionId ?? ""
                    ]))
                case .failure(let error):
                    completion(self.fail("auth_failed", error.localizedDescription))
                }
            }
        }
    }

    public func refreshToken(_ options: NSDictionary, completion: @escaping (NSDictionary) -> Void) {
        let scopes = stringArray(options["scopes"])
        client.auth.refreshToken(scopes: scopes) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    completion(self.ok([
                        "token": data.token,
                        "sessionId": data.sessionId ?? ""
                    ]))
                case .failure(let error):
                    completion(self.fail("refresh_failed", error.localizedDescription))
                }
            }
        }
    }

    public func clearAuthentication() -> NSDictionary {
        client.auth.clearAuthentication()
        return ok([:])
    }

    public func watchEvents(_ handler: @escaping (NSDictionary) -> Void) {
        bindEventsIfNeeded()
        eventHandler = handler
    }

    public func unwatchEvents() -> NSDictionary {
        eventHandler = nil
        return ok([:])
    }

    public func setNotifyEventListenCmds(_ options: NSDictionary) -> NSDictionary {
        let cmds = stringArray(options["cmds"]) ?? []
        client.setNotifyEventListenCmds(cmds)
        return ok(["cmds": cmds])
    }

    public func sendCustomCmd(_ options: NSDictionary, completion: @escaping (NSDictionary) -> Void) {
        guard let cmd = string(options["cmd"]), !cmd.isEmpty else {
            completion(fail("invalid_cmd", "cmd is required"))
            return
        }

        let payload = dataFromOptions(options)
        client.sendCustomCmd(cmd: cmd, payload: payload) { success, payload, errorCode, errorMsg in
            var data: [String: Any] = ["success": success]
            if let payload = payload {
                data["payloadBase64"] = payload.base64EncodedString()
            }
            if let errorCode = errorCode {
                data["errorCode"] = errorCode
            }
            if let errorMsg = errorMsg {
                data["errorMsg"] = errorMsg
            }
            completion(success ? self.ok(data) : self.fail("send_custom_cmd_failed", errorMsg ?? "sendCustomCmd failed", extra: data))
        }
    }

    public func openCustomView(_ options: NSDictionary, completion: @escaping (NSDictionary) -> Void) {
        guard let view = string(options["view"]) else {
            completion(fail("invalid_view", "view json string is required"))
            return
        }
        client.openCustomView(view) { success, errorCode in
            var data: [String: Any] = ["success": success]
            if let errorCode = errorCode {
                data["errorCode"] = errorCode
            }
            completion(success ? self.ok(data) : self.fail("open_custom_view_failed", "openCustomView failed", extra: data))
        }
    }

    public func updateCustomView(_ options: NSDictionary, completion: @escaping (NSDictionary) -> Void) {
        guard let view = string(options["view"]) ?? string(options["updates"]) else {
            completion(fail("invalid_view", "view or updates json string is required"))
            return
        }
        client.updateCustomView(view) { success in
            completion(success ? self.ok(["success": true]) : self.fail("update_custom_view_failed", "updateCustomView failed"))
        }
    }

    public func closeCustomView(_ options: NSDictionary, completion: @escaping (NSDictionary) -> Void) {
        guard let view = string(options["view"]) else {
            completion(fail("invalid_view", "view json string is required"))
            return
        }
        client.closeCustomView(view) { success in
            completion(success ? self.ok(["success": true]) : self.fail("close_custom_view_failed", "closeCustomView failed"))
        }
    }

    public func sendCustomViewIcons(_ options: NSDictionary, completion: @escaping (NSDictionary) -> Void) {
        guard let icons = string(options["icons"]) else {
            completion(fail("invalid_icons", "icons json string is required"))
            return
        }
        client.sendCustomViewIcons(icons) { success in
            completion(success ? self.ok(["success": true]) : self.fail("send_icons_failed", "sendCustomViewIcons failed"))
        }
    }

    public func startRecord(_ options: NSDictionary) -> NSDictionary {
        let type = string(options["type"]) ?? "test"
        client.startRecord(type, codec: audioCodec(options["codec"]), mode: audioMode(options["mode"]))
        return ok(["type": type])
    }

    public func stopRecord(_ options: NSDictionary) -> NSDictionary {
        let type = string(options["type"]) ?? "test"
        client.stopRecord(type)
        return ok(["type": type])
    }

    public func startPlayAudio(_ options: NSDictionary) -> NSDictionary {
        client.startPlayAudio(codec: audioCodec(options["codec"]))
        return ok([:])
    }

    public func stopPlayAudio() -> NSDictionary {
        client.stopPlayAudio()
        return ok([:])
    }

    public func feedAudio(_ options: NSDictionary) -> NSDictionary {
        guard let data = dataFromOptions(options) else {
            return fail("invalid_audio", "payloadBase64 or text is required")
        }
        client.feedAudio(data)
        return ok(["bytes": data.count])
    }

    public func takePhoto() -> NSDictionary {
        client.takePhoto()
        return ok([:])
    }

    public func takePhotoWithData(_ options: NSDictionary, completion: @escaping (NSDictionary) -> Void) {
        let width = int(options["width"]) ?? 1920
        let height = int(options["height"]) ?? 1080
        let quality = int(options["quality"]) ?? 80
        client.takePhotoWithData(width: width, height: height, quality: quality) { data in
            completion(self.ok([
                "payloadBase64": data.base64EncodedString(),
                "bytes": data.count,
                "width": width,
                "height": height,
                "quality": quality
            ]))
        }
    }

    public func queryApp(_ completion: @escaping (NSDictionary) -> Void) {
        client.queryApp { success in
            completion(success ? self.ok(["success": true]) : self.fail("query_app_failed", "queryApp failed"))
        }
    }

    public func openApp(_ options: NSDictionary, completion: @escaping (NSDictionary) -> Void) {
        let activityName = string(options["activityName"]) ?? "com.rokid.cxrswithcxrl.activities.main.MainActivity"
        let url = string(options["url"]) ?? ""
        client.openApp(activityName: activityName, url: url) { success in
            completion(success ? self.ok(["success": true]) : self.fail("open_app_failed", "openApp failed"))
        }
    }

    public func stopApp(_ options: NSDictionary, completion: @escaping (NSDictionary) -> Void) {
        let packageName = string(options["packageName"]) ?? defaultPackageName
        client.stopApp(packageName) { success in
            completion(success ? self.ok(["success": true]) : self.fail("stop_app_failed", "stopApp failed"))
        }
    }

    public func uninstallApp(_ options: NSDictionary, completion: @escaping (NSDictionary) -> Void) {
        let packageName = string(options["packageName"]) ?? defaultPackageName
        client.uninstallApp(packageName) { success in
            completion(success ? self.ok(["success": true]) : self.fail("uninstall_app_failed", "uninstallApp failed"))
        }
    }

    public func installApp(_ options: NSDictionary, completion: @escaping (NSDictionary) -> Void) {
        guard let path = string(options["path"]), !path.isEmpty else {
            completion(fail("invalid_path", "path is required"))
            return
        }
        client.installApp(path) { success in
            completion(success ? self.ok(["success": true]) : self.fail("install_app_failed", "installApp failed"))
        }
    }

    public func changeAudioSceneId(_ options: NSDictionary, completion: @escaping (NSDictionary) -> Void) {
        let scene = RGCxrAudioSceneId(rawValue: int(options["sceneId"]) ?? 0) ?? .interaction
        client.changeAudioSceneId(scene) { success in
            completion(success ? self.ok(["success": true]) : self.fail("change_audio_scene_failed", "changeAudioSceneId failed"))
        }
    }

    public func handleOpenURL(_ url: URL) -> Bool {
        return client.handleOpenURL(url)
    }

    public func isInitialized() -> NSDictionary {
        return ok(["initialized": initialized])
    }

    public func isAuthenticated() -> NSDictionary {
        return ok(["authenticated": client.auth.isAuthenticated()])
    }

    public func getAuthState() -> NSDictionary {
        return ok(authStatePayload(client.auth.currentState))
    }

    public func getCurrentToken() -> NSDictionary {
        return ok([
            "token": client.auth.getCurrentToken() ?? "",
            "sessionId": client.auth.getCurrentSessionId() ?? "",
            "deviceName": client.auth.getCurrentDeviceName() ?? ""
        ])
    }

    public func isRokidAppInstalled() -> NSDictionary {
        guard let url = URL(string: "rokidai://") else {
            return ok(["installed": false])
        }
        return ok(["installed": UIApplication.shared.canOpenURL(url)])
    }

    private func configureAuthFromOptions(_ options: NSDictionary?) {
        guard let options = options else { return }
        let current = client.auth.config
        client.auth.config = RGCxrClientAuthConfig(
            serverScheme: string(options["serverScheme"]) ?? current.serverScheme,
            serverHost: string(options["serverHost"]) ?? current.serverHost,
            callbackScheme: string(options["callbackScheme"]) ?? current.callbackScheme,
            callbackHost: string(options["callbackHost"]) ?? current.callbackHost,
            callbackPath: string(options["callbackPath"]) ?? current.callbackPath,
            requestTimeout: double(options["requestTimeout"]) ?? current.requestTimeout,
            timestampTolerance: double(options["timestampTolerance"]) ?? current.timestampTolerance
        )
    }

    private func emit(type: String, payload: [String: Any]) {
        var event = payload
        event["type"] = type
        DispatchQueue.main.async { [weak self] in
            self?.eventHandler?(event as NSDictionary)
        }
    }

    private func authEventPayload(_ event: RGCxrClientAuthEvent) -> [String: Any] {
        switch event {
        case .stateChanged(let state):
            return ["event": "stateChanged"].merging(authStatePayload(state)) { _, new in new }
        case .authenticationSucceeded(let token, let sessionId, let deviceName):
            return [
                "event": "authenticationSucceeded",
                "token": token,
                "sessionId": sessionId ?? "",
                "deviceName": deviceName ?? ""
            ]
        case .authenticationFailed(let error):
            return ["event": "authenticationFailed", "error": error]
        case .tokenExpired:
            return ["event": "tokenExpired"]
        @unknown default:
            return ["event": "unknown"]
        }
    }

    private func authStatePayload(_ state: RGCxrClientAuthState) -> [String: Any] {
        switch state {
        case .notAuthenticated:
            return ["state": "notAuthenticated", "authenticated": false]
        case .authenticating:
            return ["state": "authenticating", "authenticated": false]
        case .authenticated(let token, let expiresAt):
            var data: [String: Any] = ["state": "authenticated", "authenticated": true, "token": token]
            if let expiresAt = expiresAt {
                data["expiresAt"] = expiresAt
            }
            return data
        case .expired:
            return ["state": "expired", "authenticated": false]
        case .failed(let error):
            return ["state": "failed", "authenticated": false, "error": error]
        @unknown default:
            return ["state": "unknown", "authenticated": false]
        }
    }

    private func audioEventPayload(_ event: RGCxrClientAudioEvent) -> [String: Any] {
        switch event {
        case .started(let started):
            return [
                "event": "started",
                "codec": started.codec,
                "audioType": started.type,
                "channels": started.channels
            ]
        case .stream(let stream):
            return [
                "event": "stream",
                "timestamp": stream.timestamp,
                "payloadBase64": stream.data.base64EncodedString(),
                "bytes": stream.data.count
            ]
        @unknown default:
            return ["event": "unknown"]
        }
    }

    private func notifyPayload(_ event: Any) -> [String: Any] {
        var data: [String: Any] = [
            "cmd": string(mirrorValue("cmd", in: event)) ?? "",
            "subCmd": string(mirrorValue("subCmd", in: event)) ?? "",
            "reqId": int(mirrorValue("reqId", in: event)) ?? 0,
            "status": int(mirrorValue("status", in: event)) ?? 0
        ]
        if let payload = mirrorValue("payload", in: event) as? Data {
            data["payloadBase64"] = payload.base64EncodedString()
        }
        if let payloadEx = mirrorValue("payloadEx", in: event) as? Data {
            data["payloadExBase64"] = payloadEx.base64EncodedString()
        }
        return data
    }

    private func mirrorValue(_ name: String, in value: Any) -> Any? {
        var current: Mirror? = Mirror(reflecting: value)
        while let mirror = current {
            if let child = mirror.children.first(where: { $0.label == name }) {
                return unwrapOptional(child.value)
            }
            current = mirror.superclassMirror
        }
        return nil
    }

    private func unwrapOptional(_ value: Any) -> Any? {
        let mirror = Mirror(reflecting: value)
        guard mirror.displayStyle == .optional else {
            return value
        }
        return mirror.children.first.map { $0.value }
    }

    private func audioCodec(_ value: Any?) -> RGCxrAudioCodec {
        switch string(value)?.lowercased() {
        case "mp3":
            return .mp3
        case "oggopus", "ogg_opus", "opus":
            return .oggOpus
        default:
            return .pcm
        }
    }

    private func audioMode(_ value: Any?) -> RGCxrAudioMode {
        switch string(value)?.lowercased() {
        case "xf":
            return .xf
        case "rokidomni", "rokid_omni":
            return .rokidOmni
        case "antomni", "ant_omni":
            return .antOmni
        case "xforientation", "xf_orientation":
            return .xfOrientation
        case "barrierfree", "barrier_free":
            return .barrierFree
        default:
            return .antClose
        }
    }

    private func dataFromOptions(_ options: NSDictionary) -> Data? {
        if let base64 = string(options["payloadBase64"]) {
            return Data(base64Encoded: base64)
        }
        if let text = string(options["text"]) {
            return text.data(using: .utf8)
        }
        if let json = options["json"] {
            return try? JSONSerialization.data(withJSONObject: json, options: [])
        }
        return nil
    }

    private func ok(_ data: [String: Any]) -> NSDictionary {
        var result = data
        result["ok"] = true
        return result as NSDictionary
    }

    private func fail(_ code: String, _ message: String, extra: [String: Any] = [:]) -> NSDictionary {
        var result = extra
        result["ok"] = false
        result["code"] = code
        result["message"] = message
        return result as NSDictionary
    }

    private func string(_ value: Any?) -> String? {
        if let value = value as? String {
            return value
        }
        if let value = value as? NSNumber {
            return value.stringValue
        }
        return nil
    }

    private func stringArray(_ value: Any?) -> [String]? {
        if let value = value as? [String] {
            return value
        }
        if let value = value as? [Any] {
            return value.compactMap { string($0) }
        }
        return nil
    }

    private func int(_ value: Any?) -> Int? {
        if let value = value as? Int {
            return value
        }
        if let value = value as? Int32 {
            return Int(value)
        }
        if let value = value as? UInt32 {
            return Int(value)
        }
        if let value = value as? Int64 {
            return Int(value)
        }
        if let value = value as? UInt64 {
            return Int(value)
        }
        if let value = value as? NSNumber {
            return value.intValue
        }
        if let value = value as? String {
            return Int(value)
        }
        return nil
    }

    private func double(_ value: Any?) -> Double? {
        if let value = value as? Double {
            return value
        }
        if let value = value as? NSNumber {
            return value.doubleValue
        }
        if let value = value as? String {
            return Double(value)
        }
        return nil
    }
}
