package com.example.flutter_video_riche_app

import android.content.Context
import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.net.Uri
import android.os.Build
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import androidx.annotation.NonNull
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.Player
import com.google.android.exoplayer2.source.ProgressiveMediaSource
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory
import com.google.android.exoplayer2.util.Util
import com.google.android.exoplayer2.video.VideoSize
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.common.StandardMessageCodec
import java.util.concurrent.ConcurrentHashMap

class DualVideoPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    
    private val players = ConcurrentHashMap<Int, ExoPlayer>()
    private val surfaceViews = ConcurrentHashMap<Int, SurfaceView>()
    private var nextPlayerId = 1

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "dual_video_native")
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "dual_video_events")
        
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
        
        // Register platform view factory
        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            "native_video_view",
            NativeVideoViewFactory(this)
        )
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "initialize" -> initialize(result)
            "createPlayer" -> createPlayer(call, result)
            "play" -> play(call, result)
            "pause" -> pause(call, result)
            "disposePlayer" -> disposePlayer(call, result)
            "setVolume" -> setVolume(call, result)
            "seekTo" -> seekTo(call, result)
            "getCurrentPosition" -> getCurrentPosition(call, result)
            "getDuration" -> getDuration(call, result)
            "getMaxDecoders" -> getMaxDecoders(result)
            "supportsNativeSurfaces" -> supportsNativeSurfaces(result)
            "getChipsetInfo" -> getChipsetInfo(result)
            "getChipsetModel" -> getChipsetModel(result)
            "dispose" -> dispose(result)
            else -> result.notImplemented()
        }
    }

    private fun initialize(result: Result) {
        try {
            result.success(null)
        } catch (e: Exception) {
            result.error("INIT_ERROR", "Failed to initialize", e.message)
        }
    }

    private fun createPlayer(call: MethodCall, result: Result) {
        try {
            val args = call.arguments as? Map<String, Any>
            val videoUrl = args?.get("videoUrl") as? String
            val autoPlay = args?.get("autoPlay") as? Boolean ?: false
            val muted = args?.get("muted") as? Boolean ?: true
            val looping = args?.get("looping") as? Boolean ?: true

            if (videoUrl == null) {
                result.error("INVALID_ARGS", "Video URL is required", null)
                return
            }

            val playerId = nextPlayerId++
            val player = ExoPlayer.Builder(context).build()

            // Configure player
            player.volume = if (muted) 0f else 1f
            player.repeatMode = if (looping) Player.REPEAT_MODE_ONE else Player.REPEAT_MODE_OFF

            // Setup media source
            val dataSourceFactory = DefaultDataSourceFactory(
                context,
                Util.getUserAgent(context, "DualVideoApp")
            )
            val mediaSource = ProgressiveMediaSource.Factory(dataSourceFactory)
                .createMediaSource(MediaItem.fromUri(Uri.parse(videoUrl)))

            player.setMediaSource(mediaSource)
            player.prepare()

            // Setup listeners
            setupPlayerListeners(playerId, player)

            players[playerId] = player

            if (autoPlay) {
                player.play()
            }

            result.success(playerId)
        } catch (e: Exception) {
            result.error("CREATE_ERROR", "Failed to create player", e.message)
        }
    }

    private fun play(call: MethodCall, result: Result) {
        try {
            val args = call.arguments as? Map<String, Any>
            val playerId = args?.get("playerId") as? Int

            if (playerId == null) {
                result.error("INVALID_ARGS", "Player ID is required", null)
                return
            }

            val player = players[playerId]

            if (player == null) {
                result.error("PLAYER_NOT_FOUND", "Player not found", null)
                return
            }

            player.play()
            sendEvent(playerId, "playing", emptyMap<String, Any>())
            result.success(null)
        } catch (e: Exception) {
            result.error("PLAY_ERROR", "Failed to play", e.message)
        }
    }

    private fun pause(call: MethodCall, result: Result) {
        try {
            val args = call.arguments as? Map<String, Any>
            val playerId = args?.get("playerId") as? Int

            if (playerId == null) {
                result.error("INVALID_ARGS", "Player ID is required", null)
                return
            }

            val player = players[playerId]

            if (player == null) {
                result.error("PLAYER_NOT_FOUND", "Player not found", null)
                return
            }

            player.pause()
            sendEvent(playerId, "paused", emptyMap<String, Any>())
            result.success(null)
        } catch (e: Exception) {
            result.error("PAUSE_ERROR", "Failed to pause", e.message)
        }
    }

    private fun disposePlayer(call: MethodCall, result: Result) {
        try {
            val args = call.arguments as? Map<String, Any>
            val playerId = args?.get("playerId") as? Int

            if (playerId != null) {
                players[playerId]?.release()
                players.remove(playerId)
                surfaceViews.remove(playerId)
            }

            result.success(null)
        } catch (e: Exception) {
            result.error("DISPOSE_ERROR", "Failed to dispose player", e.message)
        }
    }

    private fun setVolume(call: MethodCall, result: Result) {
        try {
            val args = call.arguments as? Map<String, Any>
            val playerId = args?.get("playerId") as? Int
            val volume = args?.get("volume") as? Double
            val player = players[playerId]

            if (player == null || volume == null) {
                result.error("INVALID_ARGS", "Invalid arguments", null)
                return
            }

            player.volume = volume.toFloat().coerceIn(0f, 1f)
            result.success(null)
        } catch (e: Exception) {
            result.error("VOLUME_ERROR", "Failed to set volume", e.message)
        }
    }

    private fun seekTo(call: MethodCall, result: Result) {
        try {
            val args = call.arguments as? Map<String, Any>
            val playerId = args?.get("playerId") as? Int
            val position = args?.get("position") as? Int
            val player = players[playerId]

            if (player == null || position == null) {
                result.error("INVALID_ARGS", "Invalid arguments", null)
                return
            }

            player.seekTo(position.toLong())
            result.success(null)
        } catch (e: Exception) {
            result.error("SEEK_ERROR", "Failed to seek", e.message)
        }
    }

    private fun getCurrentPosition(call: MethodCall, result: Result) {
        try {
            val args = call.arguments as? Map<String, Any>
            val playerId = args?.get("playerId") as? Int
            val player = players[playerId]

            if (player == null) {
                result.error("PLAYER_NOT_FOUND", "Player not found", null)
                return
            }

            result.success(player.currentPosition.toInt())
        } catch (e: Exception) {
            result.error("POSITION_ERROR", "Failed to get position", e.message)
        }
    }

    private fun getDuration(call: MethodCall, result: Result) {
        try {
            val args = call.arguments as? Map<String, Any>
            val playerId = args?.get("playerId") as? Int
            val player = players[playerId]

            if (player == null) {
                result.error("PLAYER_NOT_FOUND", "Player not found", null)
                return
            }

            result.success(player.duration.toInt())
        } catch (e: Exception) {
            result.error("DURATION_ERROR", "Failed to get duration", e.message)
        }
    }

    private fun getMaxDecoders(result: Result) {
        try {
            val codecList = MediaCodecList(MediaCodecList.ALL_CODECS)
            val videoDecoders = codecList.codecInfos.filter { codecInfo ->
                !codecInfo.isEncoder && codecInfo.supportedTypes.any { type ->
                    type.startsWith("video/")
                }
            }
            
            // Estimate based on hardware capabilities
            val maxDecoders = when {
                videoDecoders.size >= 8 -> 4 // High-end devices
                videoDecoders.size >= 4 -> 2 // Mid-range devices
                else -> 1 // Low-end devices
            }
            
            result.success(maxDecoders)
        } catch (e: Exception) {
            result.success(1) // Conservative fallback
        }
    }

    private fun supportsNativeSurfaces(result: Result) {
        result.success(true) // Android always supports SurfaceView
    }

    private fun getChipsetInfo(result: Result) {
        val chipset = "${Build.MANUFACTURER} ${Build.MODEL} (${Build.SOC_MODEL ?: "Unknown"})"
        result.success(chipset)
    }

    private fun getChipsetModel(result: Result) {
        result.success(Build.SOC_MODEL ?: Build.HARDWARE)
    }

    private fun dispose(result: Result) {
        try {
            players.values.forEach { it.release() }
            players.clear()
            surfaceViews.clear()
            result.success(null)
        } catch (e: Exception) {
            result.error("DISPOSE_ERROR", "Failed to dispose", e.message)
        }
    }

    private fun setupPlayerListeners(playerId: Int, player: ExoPlayer) {
        player.addListener(object : Player.Listener {
            override fun onPlaybackStateChanged(playbackState: Int) {
                when (playbackState) {
                    Player.STATE_READY -> sendEvent(playerId, "initialized", emptyMap<String, Any>())
                    Player.STATE_ENDED -> sendEvent(playerId, "ended", emptyMap<String, Any>())
                }
            }

            override fun onPlayerError(error: com.google.android.exoplayer2.PlaybackException) {
                sendEvent(playerId, "error", mapOf("error" to (error.message ?: "Unknown error")))
            }

            override fun onVideoSizeChanged(videoSize: VideoSize) {
                sendEvent(playerId, "durationChanged", mapOf("duration" to player.duration.toInt()))
            }
        })
    }

    private fun sendEvent(playerId: Int, eventType: String, data: Map<String, Any>) {
        val event = mapOf(
            "playerId" to playerId,
            "eventType" to eventType,
            "data" to data
        )
        eventSink?.success(event)
    }

    fun getPlayer(playerId: Int): ExoPlayer? = players[playerId]

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}

class NativeVideoViewFactory(private val plugin: DualVideoPlugin) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return NativeVideoView(context, viewId, args, plugin)
    }
}

class NativeVideoView(
    context: Context,
    id: Int,
    args: Any?,
    private val plugin: DualVideoPlugin
) : PlatformView {
    private val surfaceView: SurfaceView = SurfaceView(context)
    
    init {
        val arguments = args as? Map<String, Any>
        val playerId = arguments?.get("playerId") as? Int
        
        if (playerId != null) {
            val player = plugin.getPlayer(playerId)
            player?.setVideoSurfaceView(surfaceView)
        }
    }

    override fun getView(): View = surfaceView

    override fun dispose() {
        // Cleanup handled by plugin
    }
}
