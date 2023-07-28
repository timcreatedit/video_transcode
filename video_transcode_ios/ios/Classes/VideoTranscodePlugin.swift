import Flutter
import AVFoundation

public class VideoTranscodePlugin: NSObject, FlutterPlugin {
    static let channelName = "video_transcode"
    private var clipExportSession: AVAssetExportSession? = nil
    private var concatExportSession: AVAssetExportSession? = nil
    private let channel: FlutterMethodChannel
    private let avController = AvController()

    init(channel: FlutterMethodChannel) {
        self.channel = channel
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        let instance = VideoTranscodePlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? Dictionary<String, Any>
        switch call.method {
        case "getThumbnail":
            do {
                let sourcePath = args!["sourcePath"] as! String
                let positionSeconds = args!["positionSeconds"] as! Double
                let quality = args!["quality"] as! Int
                try result(getThumbnailBytes(path: sourcePath, quality: quality, position: positionSeconds))
            } catch {
                result(FlutterError(code: "getByteThumbnail", message: "Failed to get thumbnail", details: error))
            }
            break
        case "processVideo":
            do {
                if (clipExportSession != nil) {
                    result(FlutterError(code: "processVideo", message: "A clip is already being processed", details: nil))
                }
                let sourcePath = args!["sourcePath"] as! String
                let targetPath = args!["targetPath"] as! String
                let startSeconds = args!["startSeconds"] as! NSNumber
                let durationSeconds = args!["durationSeconds"] as! NSNumber?
                let targetWidth = args!["targetWidth"] as! NSNumber?
                let targetHeight = args!["targetHeight"] as! NSNumber?
                try processClip(sourcePath: sourcePath,
                        targetPath: targetPath,
                        startSeconds: startSeconds.doubleValue,
                        durationSeconds: durationSeconds?.doubleValue,
                        targetWidth: targetWidth?.int32Value,
                        targetHeight: targetHeight?.int32Value,
                        result: result)
            } catch {
                print(error)
                result(FlutterError(code: "processVideo", message: "Failed to process video", details: error._code))
            }
            break
        case "concatVideos":
            if (concatExportSession != nil) {
                result(FlutterError(code: "concatVideos", message: "A clip is already being concatenated", details: nil))
            }
            do {
                let sourcePaths = args!["sourcePaths"] as! [String]
                let targetPath = args!["targetPath"] as! String

                try concatVideos(sourcePaths: sourcePaths,
                        destinationPath: targetPath,
                        result: result)
            } catch {
                print(error)
                result(FlutterError(code: "concatVideos", message: error.localizedDescription, details: error._code))
            }
            break
        case "getMediaInfo":
            let path = args!["path"] as! String
            result(try? getMediaInfoJson(path))
            break
        case "cancelProcess":
            clipExportSession?.cancelExport()
            concatExportSession?.cancelExport()
            result(nil)
            break
        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }

    private func getThumbnailBytes(path: String, quality: Int, position: Double) throws -> Data? {
        let url = Utility.getPathUrl(path)
        let asset = avController.getVideoAsset(url)
        guard let track = avController.getTrack(asset) else {
            return nil
        }

        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true

        let timeScale = CMTimeScale(track.nominalFrameRate)
        let time = CMTimeMakeWithSeconds(position, preferredTimescale: timeScale)
        let img = try! assetImgGenerate.copyCGImage(at: time, actualTime: nil)
        let thumbnail = UIImage(cgImage: img)
        let compressionQuality = 0.01 * Double(quality)
        return thumbnail.jpegData(compressionQuality: compressionQuality)
    }


    private func processClip(sourcePath: String,
                             targetPath: String,
                               startSeconds: Double,
                               durationSeconds: Double?,
                               targetWidth: Int32?,
                               targetHeight: Int32?,
                               result: @escaping FlutterResult) throws {
        let sourceVideoUrl = Utility.getPathUrl(sourcePath)
        let targetUrl = Utility.getPathUrl(targetPath)
        let sourceVideoAsset = avController.getVideoAsset(sourceVideoUrl)
        let uuid = NSUUID().uuidString
        let timescale = sourceVideoAsset.duration.timescale
        let videoDuration = sourceVideoAsset.duration.seconds
        let minDuration = Double(durationSeconds ?? videoDuration)
        let maxDurationTime = startSeconds + minDuration <= videoDuration ? minDuration : videoDuration

        let cmStartTime = CMTimeMakeWithSeconds(startSeconds, preferredTimescale: timescale)
        let cmDurationTime = CMTimeMakeWithSeconds(maxDurationTime, preferredTimescale: timescale)
        let timeRange: CMTimeRange = CMTimeRangeMake(start: cmStartTime, duration: cmDurationTime)


        let renderSize: CGSize?;
        if let targetWidth = targetWidth, let targetHeight = targetHeight {
            renderSize = CGSize(width: CGFloat(targetWidth), height: CGFloat(targetHeight))
        } else {
            renderSize = nil
        }

        let composition = try makeComposition(asset: sourceVideoAsset, range: timeRange)!
        let presets = AVAssetExportSession.exportPresets(compatibleWith: composition);
        let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)!
        exportSession.videoComposition = cropVideo(asset: sourceVideoAsset, composition: composition,
                renderSize: renderSize)
        exportSession.outputURL = targetUrl
        exportSession.outputFileType = AVFileType.mp4

        let timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateProgress),
                userInfo: exportSession, repeats: true)
        clipExportSession = exportSession
        exportSession.exportAsynchronously(completionHandler: {
            timer.invalidate()
            self.clipExportSession = nil
            if let error = exportSession.error {
                return result(FlutterError(code: "processClip", message: error.localizedDescription, details: error._code))
            }
            return result(try? self.getMediaInfoJson(Utility.excludeEncoding(targetPath)))
        })
    }


    private func makeComposition(asset: AVURLAsset, range: CMTimeRange) throws -> AVMutableComposition? {
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            return nil
        }
        let audioTrack = asset.tracks(withMediaType: .audio).first;

        let comp = AVMutableComposition();
        guard let compVideoTrack = comp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        else {
            return nil
        }
        try compVideoTrack.insertTimeRange(range, of: videoTrack, at: .zero)

        if let audioTrack = audioTrack, let compAudioTrack = comp.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            try compAudioTrack.insertTimeRange(range, of: audioTrack, at: .zero)
        }
        return comp
    }


    private func cropVideo(asset: AVAsset, composition: AVMutableComposition, renderSize: CGSize?) -> AVVideoComposition {
        let track = asset.tracks(withMediaType: AVMediaType.video)[0]
        let compTrack = composition.tracks(withMediaType: .video)[0]
        let trackSize = track.naturalSize.applying(track.preferredTransform)
        let renderSize = renderSize ?? track.naturalSize

        let wr = renderSize.width / trackSize.width;
        let hr = renderSize.height / trackSize.height;
        let ratio = wr > hr ? wr : hr
        let scaleTransform = track.preferredTransform
                .concatenating(CGAffineTransform(scaleX: ratio, y: ratio))
        let newSize = trackSize
        let offset = CGPoint(x: (renderSize.width - abs(newSize.width * ratio)) / 2,
                y: (renderSize.height - abs(newSize.height * ratio)) / 2)
        let finalTransform = scaleTransform
                .concatenating(CGAffineTransform(translationX: offset.x, y: offset.y))
        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: compTrack)
        transformer.setTransform(finalTransform, at: .zero)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: .zero, duration: asset.duration)
        instruction.layerInstructions = [transformer]

        let videoComposition = AVMutableVideoComposition()

        videoComposition.frameDuration = asset.tracks(withMediaType: .video)[0].minFrameDuration
        videoComposition.renderSize = renderSize
        videoComposition.instructions = [instruction]
        return videoComposition
    }

    private func concatVideos(sourcePaths: [String],
                              destinationPath: String,
                              result: @escaping FlutterResult) throws {
        let composition = AVMutableComposition()
        let destinationUrl = Utility.getPathUrl(destinationPath)
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        else {
            return
        }

        var time = CMTime.zero

        for sourcePath in sourcePaths {
            let sourceVideoUrl = Utility.getPathUrl(sourcePath)
            let sourceVideoAsset = avController.getVideoAsset(sourceVideoUrl)

            let sourceVideoTrack = sourceVideoAsset.tracks(withMediaType: .video).first
            let sourceAudioTrack = sourceVideoAsset.tracks(withMediaType: .audio).first
            guard let sourceVideoTrack = sourceVideoTrack else { continue }
            try videoTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: sourceVideoAsset.duration), of: sourceVideoTrack, at: time)
            
            if let sourceAudioTrack = sourceAudioTrack {
                         try audioTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: sourceVideoAsset.duration), of: sourceAudioTrack, at: time)
                     }
            time = CMTimeAdd(time, sourceVideoAsset.duration)
        }
        Utility.deleteFile(destinationPath, clear: true)
        let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough)!
        exportSession.outputURL = destinationUrl
        exportSession.outputFileType = AVFileType.mp4

        let timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateProgress),
                userInfo: exportSession, repeats: true)
        concatExportSession = exportSession
        exportSession.exportAsynchronously(completionHandler: {
            timer.invalidate()
            self.concatExportSession = nil
            return result(try? self.getMediaInfoJson(Utility.excludeEncoding(destinationUrl.path)))
        })
    }


    public func getMediaInfoJson(_ path: String) throws -> Dictionary<String, Any?>  {
        let url = Utility.getPathUrl(path)
        let asset = avController.getVideoAsset(url)
        guard let track = avController.getTrack(asset) else {
            throw NSError(domain: "file not found", code: 404, userInfo: nil)
        }

        let playerItem = AVPlayerItem(url: url)
        let metadataAsset = playerItem.asset

        let orientation = avController.getVideoOrientation(path)
        let title = avController.getMetaDataByTag(metadataAsset, key: "title")
        let author = avController.getMetaDataByTag(metadataAsset, key: "author")
        let duration = asset.duration.seconds
        let filesize = track.totalSampleDataLength
        let size = track.naturalSize.applying(track.preferredTransform)

        let width = NSInteger(abs(size.width))
        let height = NSInteger(abs(size.height))

        return [
            "path": Utility.excludeFileProtocol(path),
            "width": width,
            "height": height,
            "duration": duration,
            "fileSize": filesize,
            "title": title,
            "author": author,
            "orientation": orientation
        ]
    }


    @objc private func updateProgress(timer: Timer) {
        let asset = timer.userInfo as! AVAssetExportSession
        channel.invokeMethod("updateProgress", arguments: String(describing: asset.progress))
    }
}
