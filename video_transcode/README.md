# video_transcode (BETA)

![coverage][coverage_badge]
[![License: MIT][license_badge]][license_link]

Video Transcode is a library that uses native APIs to allow basic video operations.
---

This plugin is in development at the moment. Things might go wrong and APIs might change without warning.
If you have feedback, feel free to contribute or reach out on [Twitter](https://twitter.com/imadetheseworks)

---

## Why do I want this?
Lots of video apps use FFMPEG for video manipulation tasks and while there is nothing wrong with that, there are a couple of advantages that come with using native APIs for this:

- Use H264 and HEVC codecs without licensing
- Faster by default
- Easier memory management
- Simple HDR tonemapping
- ...

## Features

### Included (basic functionality)
- [x] Trim videos
- [x] Resize video frame (so far only with BoxFit.cover)
- [x] Concat videos
- [x] Extract metadata
- [x] Generate thumbnails (rudimentary)

### Planned
- [ ] Resize with more fitting algorithms
- [ ] Output quality control
- [ ] Support other containers
- [ ] Filters
- [ ] macOS support

## Caveats
- For concat on Android, all videos *must* contain an audio track.
- 

[coverage_badge]: coverage_badge.svg
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
