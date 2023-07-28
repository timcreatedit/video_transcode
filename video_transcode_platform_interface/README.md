# video_transcode_platform_interface

A common platform interface for the `video_transcode` plugin.

This interface allows platform-specific implementations of the `video_transcode` plugin, as well as the plugin itself, to ensure they are supporting the same interface.

# Usage

To implement a new platform-specific implementation of `video_transcode`, extend `VideoTranscodePlatform` with an implementation that performs the platform-specific behavior.
