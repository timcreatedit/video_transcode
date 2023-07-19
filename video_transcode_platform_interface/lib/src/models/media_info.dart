import 'dart:io';

import 'package:flutter/foundation.dart';

@immutable
class MediaInfo {
  /// A [MediaInfo] describes a media file.
  const MediaInfo({
    required this.file,
    required this.size,
    required this.duration,
    required this.filesize,
    this.title,
    this.author,
    this.orientation,
  });

  final File file;
  final ({int width, int height}) size;

  final Duration duration;

  /// The file size in bytes
  final int filesize;

  final String? title;
  final String? author;

  /// [Android] API level 17
  final int? orientation;

  factory MediaInfo.fromJson(Map<String, dynamic> map) {
    try {
      switch (map) {
        case {
            "file": final String file,
            "width": final int width,
            "height": final int height,
            "duration": final double duration,
            "filesize": final int filesize,
          }:
          return MediaInfo(
            file: File(file),
            size: (width: width, height: height),
            duration: Duration(milliseconds: (1000 * duration).toInt()),
            filesize: filesize,
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
      "file": file.path,
      "width": size.width,
      "height": size.height,
      "duration": duration.inMilliseconds / 1000,
      "filesize": filesize,
      "title": title,
      "author": author,
      "orientation": orientation,
    };
  }
}
