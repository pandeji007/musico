# Performance Optimization and Storage Improvements

The goal is to resolve the significant slowdown in the app, particularly during music playback and data retrieval, by optimizing Hive initialization, improving audio caching logic, and refining the data storage strategy.

## User Review Required

> [!IMPORTANT]
> The most critical change is how audio files are handled. Currently, the app downloads the **entire** file before playing. I will change this to start playing immediately from the network while caching in the background.

## Proposed Changes

### Core Optimization

#### [MODIFY] [main.dart](file:///C:/Harshal/choira%20assignment/tuneflow/lib/main.dart)
- Initialize `Hive` and open required boxes at app startup to avoid repeated initialization overhead.

#### [MODIFY] [dio_client.dart](file:///C:/Harshal/choira%20assignment/tuneflow/lib/core/network/dio_client.dart)
- Expose the `Dio` instance more efficiently for use in other parts of the app (like audio caching).

### Music Feature Optimization

#### [MODIFY] [music_local_data_source.dart](file:///C:/Harshal/choira%20assignment/tuneflow/lib/features/music/data/datasources/music_local_data_source.dart)
- Remove lazy `init()` calls from every method.
- Update `cacheAudio` to use the shared `Dio` client.
- Optimize `cacheTracks` to avoid redundant encoding if possible (or keep it as is but ensure it's not called unnecessarily).

#### [MODIFY] [music_repository_impl.dart](file:///C:/Harshal/choira%20assignment/tuneflow/lib/features/music/domain/repositories/music_repository_impl.dart)
- Remove redundant `localDataSource.init()` calls.

#### [MODIFY] [audio_player_provider.dart](file:///C:/Harshal/choira%20assignment/tuneflow/lib/features/music/presentation/providers/audio_player_provider.dart)
- **Critical Fix:** Modify `playTrack` to check for cached audio first. If not found, start playing from the URL immediately and trigger a background download/cache process instead of waiting for the full download.
- Remove `localDataSource.init()` from `playTrack`.
- Use the shared `MusicLocalDataSource` from the provider instead of creating a new instance.

## Verification Plan

### Manual Verification
- Verify that songs start playing almost instantly after tapping.
- Monitor memory usage during playback to ensure no OOM issues.
- Confirm that songs are still cached and playable offline after the first play.
- Check that the home screen loads quickly using cached data.
