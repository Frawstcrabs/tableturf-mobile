//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import audio_session
import firebase_core
import firebase_crashlytics
import games_services
import just_audio
import path_provider_macos
import shared_preferences_macos
import soundpool_macos

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  AudioSessionPlugin.register(with: registry.registrar(forPlugin: "AudioSessionPlugin"))
  FLTFirebaseCorePlugin.register(with: registry.registrar(forPlugin: "FLTFirebaseCorePlugin"))
  FLTFirebaseCrashlyticsPlugin.register(with: registry.registrar(forPlugin: "FLTFirebaseCrashlyticsPlugin"))
  GamesServicesPlugin.register(with: registry.registrar(forPlugin: "GamesServicesPlugin"))
  JustAudioPlugin.register(with: registry.registrar(forPlugin: "JustAudioPlugin"))
  PathProviderPlugin.register(with: registry.registrar(forPlugin: "PathProviderPlugin"))
  SharedPreferencesPlugin.register(with: registry.registrar(forPlugin: "SharedPreferencesPlugin"))
  SwiftSoundpoolPlugin.register(with: registry.registrar(forPlugin: "SwiftSoundpoolPlugin"))
}
