import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

/// Enhanced video cache manager with proxy-like caching capabilities
/// Similar to KTVHTTP for iOS and proxy caching for Android
class EnhancedVideoCacheManager {
  static EnhancedVideoCacheManager? _instance;
  static EnhancedVideoCacheManager get instance => _instance ??= EnhancedVideoCacheManager._();

  late final Dio _dio;
  late final CacheOptions _cacheOptions;
  late final DefaultCacheManager _thumbnailCacheManager;
  
  EnhancedVideoCacheManager._();

  /// Initialize the cache manager
  Future<void> initialize() async {
    final cacheDir = await getTemporaryDirectory();
    final videoCacheDir = Directory('${cacheDir.path}/video_cache');
    final thumbnailCacheDir = Directory('${cacheDir.path}/thumbnail_cache');
    
    // Ensure directories exist
    await videoCacheDir.create(recursive: true);
    await thumbnailCacheDir.create(recursive: true);

    // Setup cache options for videos
    _cacheOptions = CacheOptions(
      store: FileCacheStore(videoCacheDir.path),
      policy: CachePolicy.forceCache,
      hitCacheOnErrorExcept: [401, 403, 404],
      maxStale: const Duration(days: 7), // Keep videos for 7 days
      priority: CachePriority.high,
      cipher: null,
      keyBuilder: (request) => request.uri.toString(),
      allowPostMethod: false,
    );

    // Setup Dio with caching interceptor
    _dio = Dio();
    _dio.interceptors.add(DioCacheInterceptor(options: _cacheOptions));
    
    // Add logging interceptor for debugging
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (obj) => print('[VideoCache] $obj'),
    ));

    // Setup thumbnail cache manager
    _thumbnailCacheManager = DefaultCacheManager();
  }

  /// Get cached video URL or cache it if not available
  /// This acts as a proxy layer similar to KTVHTTP
  Future<String> getCachedVideoUrl(String originalUrl) async {
    try {
      print('[VideoCache] 🔍 Checking cache for: $originalUrl');

      // Check if video is already cached
      final cacheKey = originalUrl;
      final cachedResponse = await _cacheOptions.store?.get(cacheKey);

      if (cachedResponse != null) {
        // Video is cached - return original URL since dio will serve from cache
        print('[VideoCache] ✅ Video FOUND in cache: $originalUrl');
        print('[VideoCache] 📱 Cache size: ${cachedResponse.content?.length ?? 0} bytes');
        print('[VideoCache] 🔄 Will replay from CACHE');
        return originalUrl;
      }

      // If not cached, start background caching and return original URL
      print('[VideoCache] ❌ Video NOT in cache: $originalUrl');
      print('[VideoCache] 📥 Starting background download...');
      _cacheVideoInBackground(originalUrl);
      return originalUrl;

    } catch (e) {
      print('[VideoCache] ⚠️ Error getting cached video: $e');
      return originalUrl;
    }
  }

  /// Cache video in background
  Future<void> _cacheVideoInBackground(String url) async {
    try {
      print('[VideoCache] 📥 Starting background cache for: $url');
      final startTime = DateTime.now();

      final response = await _dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Accept': 'video/*',
            'User-Agent': 'Flutter Video Player',
          },
        ),
      );

      if (response.statusCode == 200) {
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);
        final sizeInMB = (response.data?.length ?? 0) / (1024 * 1024);

        print('[VideoCache] ✅ Successfully cached video: $url');
        print('[VideoCache] 📊 Size: ${sizeInMB.toStringAsFixed(2)} MB');
        print('[VideoCache] ⏱️ Download time: ${duration.inMilliseconds}ms');
        print('[VideoCache] 💾 Video is now available for CACHE REPLAY');
      } else {
        print('[VideoCache] ⚠️ Failed to cache video: $url (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('[VideoCache] ❌ Error caching video: $e');
    }
  }

  /// Check if a video is cached
  Future<bool> isVideoCached(String videoUrl) async {
    try {
      final cacheKey = videoUrl;
      final cachedResponse = await _cacheOptions.store?.get(cacheKey);
      final isCached = cachedResponse != null;

      print('[VideoCache] 🔍 Cache check for: $videoUrl');
      print('[VideoCache] ${isCached ? '✅ CACHED' : '❌ NOT CACHED'}');

      return isCached;
    } catch (e) {
      print('[VideoCache] ⚠️ Error checking cache: $e');
      return false;
    }
  }

  /// Pre-cache multiple videos
  Future<void> preCacheVideos(List<String> videoUrls) async {
    print('[VideoCache] 📥 Pre-caching ${videoUrls.length} videos');

    for (final url in videoUrls) {
      final isCached = await isVideoCached(url);
      if (!isCached) {
        _cacheVideoInBackground(url);
        // Small delay to prevent overwhelming the network
        await Future.delayed(const Duration(milliseconds: 100));
      } else {
        print('[VideoCache] ⏭️ Skipping already cached: $url');
      }
    }
  }

  /// Get cached thumbnail
  Future<File?> getCachedThumbnail(String thumbnailUrl) async {
    try {
      return await _thumbnailCacheManager.getSingleFile(thumbnailUrl);
    } catch (e) {
      print('[VideoCache] Error getting cached thumbnail: $e');
      return null;
    }
  }

  /// Pre-cache thumbnail
  Future<void> preCacheThumbnail(String thumbnailUrl) async {
    try {
      await _thumbnailCacheManager.downloadFile(thumbnailUrl);
      print('[VideoCache] Successfully cached thumbnail: $thumbnailUrl');
    } catch (e) {
      print('[VideoCache] Error caching thumbnail: $e');
    }
  }

  /// Clear video cache
  Future<void> clearVideoCache() async {
    try {
      await _cacheOptions.store?.clean();
      print('[VideoCache] Video cache cleared');
    } catch (e) {
      print('[VideoCache] Error clearing video cache: $e');
    }
  }

  /// Clear thumbnail cache
  Future<void> clearThumbnailCache() async {
    try {
      await _thumbnailCacheManager.emptyCache();
      print('[VideoCache] Thumbnail cache cleared');
    } catch (e) {
      print('[VideoCache] Error clearing thumbnail cache: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final videoStore = _cacheOptions.store;
      final cacheDir = await getTemporaryDirectory();
      final videoCacheDir = Directory('${cacheDir.path}/video_cache');

      int cachedVideoCount = 0;
      int totalCacheSize = 0;

      if (await videoCacheDir.exists()) {
        final files = videoCacheDir.listSync();
        cachedVideoCount = files.length;

        for (final file in files) {
          if (file is File) {
            totalCacheSize += await file.length();
          }
        }
      }

      final cacheSizeMB = totalCacheSize / (1024 * 1024);

      print('[VideoCache] 📊 Cache Statistics:');
      print('[VideoCache] 📁 Cached videos: $cachedVideoCount');
      print('[VideoCache] 💾 Total cache size: ${cacheSizeMB.toStringAsFixed(2)} MB');

      return {
        'videoCacheEnabled': videoStore != null,
        'thumbnailCacheEnabled': true,
        'cacheDirectory': cacheDir.path,
        'cachedVideoCount': cachedVideoCount,
        'totalCacheSizeMB': cacheSizeMB,
        'totalCacheSizeBytes': totalCacheSize,
      };
    } catch (e) {
      print('[VideoCache] ⚠️ Error getting cache stats: $e');
      return {'error': e.toString()};
    }
  }

  /// Get cache size information (legacy method)
  Future<Map<String, dynamic>> getCacheInfo() async {
    return getCacheStats();
  }

  /// Dispose resources
  void dispose() {
    _dio.close();
  }
}
