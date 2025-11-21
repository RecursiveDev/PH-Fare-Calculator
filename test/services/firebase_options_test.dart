import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ph_fare_estimator/firebase_options.dart';

void main() {
  group('DefaultFirebaseOptions', () {
    late Map<String, String> envVars;

    setUpAll(() async {
      // Load the .env file from the root directory
      final envFile = File('.env');
      if (!envFile.existsSync()) {
        throw Exception('.env file not found in root directory. Please ensure you are running tests from the project root.');
      }
      final envContent = await envFile.readAsString();
      
      // Parse the .env content manually for independent verification
      envVars = _parseEnvLines(envContent);

      // Load dotenv with the content to simulate the environment
      dotenv.loadFromString(envString: envContent);
    });

    tearDown(() {
      // Reset the platform override after each test
      debugDefaultTargetPlatformOverride = null;
    });

    test('Android platform loads correct API Key from .env', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final options = DefaultFirebaseOptions.currentPlatform;
      
      expect(options.apiKey, equals(envVars['FIREBASE_ANDROID_API_KEY']),
          reason: 'Android API key should match .env file');
      expect(options.projectId, 'ph-fare-calculator');
    });

    test('iOS platform loads correct API Key from .env', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final options = DefaultFirebaseOptions.currentPlatform;
      
      expect(options.apiKey, equals(envVars['FIREBASE_IOS_API_KEY']),
          reason: 'iOS API key should match .env file');
      expect(options.projectId, 'ph-fare-calculator');
    });

    test('macOS platform loads correct API Key from .env', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final options = DefaultFirebaseOptions.currentPlatform;
      
      expect(options.apiKey, equals(envVars['FIREBASE_MACOS_API_KEY']),
          reason: 'macOS API key should match .env file');
      expect(options.projectId, 'ph-fare-calculator');
    });

    test('Windows platform loads correct API Key from .env', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final options = DefaultFirebaseOptions.currentPlatform;
      
      expect(options.apiKey, equals(envVars['FIREBASE_WINDOWS_API_KEY']),
          reason: 'Windows API key should match .env file');
      expect(options.projectId, 'ph-fare-calculator');
    });

    test('Web platform loads correct API Key from .env', () {
      // Note: kIsWeb cannot be mocked to true in a Dart VM test environment to trigger 
      // currentPlatform to return web options. We test the static getter directly.
      final options = DefaultFirebaseOptions.web;
      
      expect(options.apiKey, equals(envVars['FIREBASE_WEB_API_KEY']),
          reason: 'Web API key should match .env file');
      expect(options.projectId, 'ph-fare-calculator');
    });
  });
}

/// Simple helper to parse .env content into a Map
Map<String, String> _parseEnvLines(String content) {
  final map = <String, String>{};
  final lines = content.split('\n');
  for (var line in lines) {
    line = line.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    
    final parts = line.split('=');
    if (parts.length >= 2) {
      final key = parts[0].trim();
      // Join the rest in case the value contains '='
      final value = parts.sublist(1).join('=').trim();
      map[key] = value;
    }
  }
  return map;
}