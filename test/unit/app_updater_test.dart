import 'package:flutter_test/flutter_test.dart';
import 'package:todohuy/core/updater/app_updater.dart';

void main() {
  group('AppUpdater.isVersionNewer Tests', () {
    test('returns true when remote major version is higher', () {
      final result = AppUpdater.isVersionNewer(
        remoteTag: 'v2.0.0',
        localVersion: '1.0.0',
        localBuildNumber: 1,
      );
      expect(result, isTrue);
    });

    test('returns true when remote minor version is higher', () {
      final result = AppUpdater.isVersionNewer(
        remoteTag: '1.1.0',
        localVersion: '1.0.0',
        localBuildNumber: 1,
      );
      expect(result, isTrue);
    });

    test('returns true when remote patch version is higher', () {
      final result = AppUpdater.isVersionNewer(
        remoteTag: 'v1.0.1',
        localVersion: '1.0.0',
        localBuildNumber: 1,
      );
      expect(result, isTrue);
    });

    test('returns true when remote build number is higher for same version', () {
      final result = AppUpdater.isVersionNewer(
        remoteTag: 'v1.0.0+2',
        localVersion: '1.0.0',
        localBuildNumber: 1,
      );
      expect(result, isTrue);
    });

    test('returns true for CI build run number tag (e.g. v1.0.0+1.5)', () {
      final result = AppUpdater.isVersionNewer(
        remoteTag: 'v1.0.0+1.5',
        localVersion: '1.0.0',
        localBuildNumber: 1,
      );
      expect(result, isTrue);
    });

    test('returns false when remote version is equal to local', () {
      final result = AppUpdater.isVersionNewer(
        remoteTag: 'v1.0.0+1',
        localVersion: '1.0.0',
        localBuildNumber: 1,
      );
      expect(result, isFalse);
    });

    test('returns false when remote version is older', () {
      final result = AppUpdater.isVersionNewer(
        remoteTag: 'v0.9.5',
        localVersion: '1.0.0',
        localBuildNumber: 1,
      );
      expect(result, isFalse);
    });

    test('handles empty or malformed remote tag safely', () {
      expect(
        AppUpdater.isVersionNewer(
          remoteTag: '',
          localVersion: '1.0.0',
          localBuildNumber: 1,
        ),
        isFalse,
      );
      expect(
        AppUpdater.isVersionNewer(
          remoteTag: 'invalid-tag',
          localVersion: '1.0.0',
          localBuildNumber: 1,
        ),
        isFalse,
      );
    });
  });
}
