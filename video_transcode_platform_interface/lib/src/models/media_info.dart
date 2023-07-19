import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class MediaInfo with EquatableMixin {
  /// A [MediaInfo] describes a media file.
  const MediaInfo({
    required this.file,
    required this.frameSize,
    required this.duration,
    required this.fileSize,
    this.title,
    this.author,
    this.orientation,
  });

  final File file;
  final ({int width, int height}) frameSize;

  final Duration duration;

  /// The file size in bytes
  final int fileSize;

  final String? title;
  final String? author;

  final int? orientation;

  factory MediaInfo.fromJson(Map<String, dynamic> map) {
    try {
      switch (map) {
        case {
            "path": final String path,
            "width": final int width,
            "height": final int height,
            "duration": final double duration,
            "fileSize": final int fileSize,
          }:
          return MediaInfo(
            file: File(path),
            frameSize: (width: width, height: height),
            duration: Duration(milliseconds: (1000 * duration).toInt()),
            fileSize: fileSize,
            title: map["title"] as String?,
            author: map["author"] as String?,
            orientation: map["orientation"] as int?,
          );
        default:
          throw ArgumentError.value(map, "map", "Invalid JSON");
      }
    } catch (e) {
      throw ArgumentError.value(map, "map", "Invalid JSON");
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "path": file.path,
      "width": frameSize.width,
      "height": frameSize.height,
      "duration": duration.inMilliseconds / 1000,
      "fileSize": fileSize,
      "title": title,
      "author": author,
      "orientation": orientation,
    };
  }

  @override
  List<Object?> get props => [
        file.path,
        frameSize,
        duration,
        fileSize,
        title,
        author,
        orientation,
      ];
}
