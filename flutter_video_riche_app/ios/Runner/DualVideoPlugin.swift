import Flutter
import UIKit
import AVFoundation

public class DualVideoPlugin: NSObject, FlutterPlugin {
    private var players: [Int: AVPlayer] = [:]
    private var playerLayers: [Int: AVPlayerLayer] = [:]
    private var playerViews: [Int: UIView] = [:]
    private var nextPlayerId = 1
    private var eventSink: FlutterEventSink?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(name: "dual_video_native", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "dual_video_events", binaryMessenger: registrar.messenger())
        
        let instance = DualVideoPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
        
        // Register platform view factory for native video views
        registrar.register(
            NativeVideoViewFactory(plugin: instance),
            withId: "native_video_view"
        )
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            initialize(result: result)
        case "createPlayer":
            createPlayer(call: call, result: result)
        case "play":
            play(call: call, result: result)
        case "pause":
            pause(call: call, result: result)
        case "disposePlayer":
            disposePlayer(call: call, result: result)
        case "setVolume":
            setVolume(call: call, result: result)
        case "seekTo":
            seekTo(call: call, result: result)
        case "getCurrentPosition":
            getCurrentPosition(call: call, result: result)
        case "getDuration":
            getDuration(call: call, result: result)
        case "getMaxDecoders":
            getMaxDecoders(result: result)
        case "supportsNativeSurfaces":
            supportsNativeSurfaces(result: result)
        case "getChipsetInfo":
            getChipsetInfo(result: result)
        case "getDeviceModel":
            getDeviceModel(result: result)
        case "dispose":
            dispose(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func initialize(result: @escaping FlutterResult) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            result(nil)
        } catch {
            result(FlutterError(code: "INIT_ERROR", message: "Failed to initialize audio session", details: error.localizedDescription))
        }
    }
    
    private func createPlayer(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let videoUrl = args["videoUrl"] as? String,
              let url = URL(string: videoUrl) else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        let playerId = nextPlayerId
        nextPlayerId += 1
        
        let player = AVPlayer(url: url)
        players[playerId] = player
        
        // Configure player
        if let muted = args["muted"] as? Bool, muted {
            player.isMuted = true
        }
        
        if let looping = args["looping"] as? Bool, looping {
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main
            ) { [weak self] _ in
                player.seek(to: .zero)
                player.play()
            }
        }
        
        // Create player layer
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayers[playerId] = playerLayer
        
        // Setup observers
        setupPlayerObservers(playerId: playerId, player: player)
        
        if let autoPlay = args["autoPlay"] as? Bool, autoPlay {
            player.play()
        }
        
        result(playerId)
    }
    
    private func play(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let playerId = args["playerId"] as? Int,
              let player = players[playerId] else {
            result(FlutterError(code: "PLAYER_NOT_FOUND", message: "Player not found", details: nil))
            return
        }
        
        player.play()
        sendEvent(playerId: playerId, eventType: "playing", data: [:])
        result(nil)
    }
    
    private func pause(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let playerId = args["playerId"] as? Int,
              let player = players[playerId] else {
            result(FlutterError(code: "PLAYER_NOT_FOUND", message: "Player not found", details: nil))
            return
        }
        
        player.pause()
        sendEvent(playerId: playerId, eventType: "paused", data: [:])
        result(nil)
    }
    
    private func disposePlayer(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let playerId = args["playerId"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        players[playerId]?.pause()
        players.removeValue(forKey: playerId)
        playerLayers.removeValue(forKey: playerId)
        playerViews.removeValue(forKey: playerId)
        
        result(nil)
    }
    
    private func setVolume(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let playerId = args["playerId"] as? Int,
              let volume = args["volume"] as? Double,
              let player = players[playerId] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        player.volume = Float(volume)
        result(nil)
    }
    
    private func seekTo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let playerId = args["playerId"] as? Int,
              let position = args["position"] as? Int,
              let player = players[playerId] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        let time = CMTime(value: Int64(position), timescale: 1000)
        player.seek(to: time)
        result(nil)
    }
    
    private func getCurrentPosition(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let playerId = args["playerId"] as? Int,
              let player = players[playerId] else {
            result(FlutterError(code: "PLAYER_NOT_FOUND", message: "Player not found", details: nil))
            return
        }
        
        let position = Int(player.currentTime().seconds * 1000)
        result(position)
    }
    
    private func getDuration(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let playerId = args["playerId"] as? Int,
              let player = players[playerId],
              let duration = player.currentItem?.duration else {
            result(FlutterError(code: "PLAYER_NOT_FOUND", message: "Player not found", details: nil))
            return
        }
        
        let durationMs = Int(duration.seconds * 1000)
        result(durationMs)
    }
    
    private func getMaxDecoders(result: @escaping FlutterResult) {
        // iOS typically supports 4+ hardware decoders on modern devices
        let deviceModel = UIDevice.current.model
        if deviceModel.contains("iPhone") {
            result(4) // Most iPhones support multiple decoders
        } else if deviceModel.contains("iPad") {
            result(6) // iPads typically have more powerful hardware
        } else {
            result(2) // Conservative fallback
        }
    }
    
    private func supportsNativeSurfaces(result: @escaping FlutterResult) {
        result(true) // iOS always supports AVPlayerLayer
    }
    
    private func getChipsetInfo(result: @escaping FlutterResult) {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value))!)
        }
        result("iOS \(identifier)")
    }
    
    private func getDeviceModel(result: @escaping FlutterResult) {
        result(UIDevice.current.model)
    }
    
    private func dispose(result: @escaping FlutterResult) {
        for player in players.values {
            player.pause()
        }
        players.removeAll()
        playerLayers.removeAll()
        playerViews.removeAll()
        result(nil)
    }
    
    private func setupPlayerObservers(playerId: Int, player: AVPlayer) {
        // Add time observer for position updates
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            let position = Int(time.seconds * 1000)
            self?.sendEvent(playerId: playerId, eventType: "positionChanged", data: ["position": position])
        }
        
        // Add status observer
        player.addObserver(self, forKeyPath: "status", options: [.new], context: &playerId)
    }
    
    private func sendEvent(playerId: Int, eventType: String, data: [String: Any]) {
        let event: [String: Any] = [
            "playerId": playerId,
            "eventType": eventType,
            "data": data
        ]
        eventSink?(event)
    }
    
    func getPlayerLayer(playerId: Int) -> AVPlayerLayer? {
        return playerLayers[playerId]
    }
}

// MARK: - FlutterStreamHandler
extension DualVideoPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}

// MARK: - Platform View Factory
class NativeVideoViewFactory: NSObject, FlutterPlatformViewFactory {
    private let plugin: DualVideoPlugin
    
    init(plugin: DualVideoPlugin) {
        self.plugin = plugin
        super.init()
    }
    
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return NativeVideoView(frame: frame, viewId: viewId, args: args, plugin: plugin)
    }
}

// MARK: - Platform View
class NativeVideoView: NSObject, FlutterPlatformView {
    private let _view: UIView
    private let plugin: DualVideoPlugin
    
    init(frame: CGRect, viewId: Int64, args: Any?, plugin: DualVideoPlugin) {
        self.plugin = plugin
        self._view = UIView(frame: frame)
        super.init()
        
        if let arguments = args as? [String: Any],
           let playerId = arguments["playerId"] as? Int,
           let playerLayer = plugin.getPlayerLayer(playerId: playerId) {
            playerLayer.frame = _view.bounds
            _view.layer.addSublayer(playerLayer)
        }
    }
    
    func view() -> UIView {
        return _view
    }
}
