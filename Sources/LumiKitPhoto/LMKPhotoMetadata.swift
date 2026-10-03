//
//  LMKPhotoMetadata.swift
//  LumiKit
//
//  Reads the capture date, GPS coordinate, pixel size, and orientation out of
//  image bytes, and writes a date and coordinate back into them.
//

import CoreLocation
import ImageIO
import LumiKitCore
@preconcurrency import PhotosUI
import UIKit
import UniformTypeIdentifiers

/// Photo metadata read from raw image bytes.
///
/// Always read from the original bytes (`loadDataRepresentation`, a file URL): a decoded
/// `UIImage` has no metadata left, so there is deliberately no `UIImage` overload.
/// ```swift
/// let metadata = await LMKPhotoMetadata.read(from: pickerResult)
/// let stamped = LMKPhotoMetadata.write(date: metadata.date, coordinate: metadata.coordinate, to: jpegData)
/// ```
public nonisolated struct LMKPhotoMetadata: Sendable, Equatable {
    /// The capture date, walking EXIF, TIFF, IPTC, and XMP in capture-fidelity order. An EXIF
    /// date is an instant when the file carries its `OffsetTime` tag; without one it is read as
    /// wall time in the device's current time zone.
    public var date: Date?
    /// The GPS position, `nil` when absent or invalid.
    public var coordinate: CLLocationCoordinate2D?
    /// The pixel size with the orientation applied.
    public var pixelSize: CGSize?
    /// The stored EXIF orientation; `.up` when the file carries none.
    public var orientation: CGImagePropertyOrientation

    public init(date: Date? = nil, coordinate: CLLocationCoordinate2D? = nil, pixelSize: CGSize? = nil, orientation: CGImagePropertyOrientation = .up) {
        self.date = date
        self.coordinate = coordinate
        self.pixelSize = pixelSize
        self.orientation = orientation
    }

    /// No metadata at all.
    public static let empty = Self()

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.date == rhs.date
            && lhs.coordinate?.latitude == rhs.coordinate?.latitude
            && lhs.coordinate?.longitude == rhs.coordinate?.longitude
            && lhs.pixelSize == rhs.pixelSize
            && lhs.orientation == rhs.orientation
    }

    // MARK: - Reading

    /// The metadata in `data`; `.empty` when the bytes are not an image.
    public static func read(from data: Data) -> Self {
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return .empty }
        return read(from: source)
    }

    /// The metadata in the file at `fileURL`; `.empty` when it is not an image.
    public static func read(from fileURL: URL) -> Self {
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, sourceOptions) else { return .empty }
        return read(from: source)
    }

    /// The metadata of a `PHPickerViewController` result, read from the original bytes so it
    /// survives the pick. `.empty` when the provider has no image data.
    public static func read(from result: PHPickerResult) async -> Self {
        await read(from: result.itemProvider)
    }

    /// The metadata of an item provider's image representation; `.empty` when it has none.
    public static func read(from provider: NSItemProvider) async -> Self {
        await withCheckedContinuation { continuation in
            _ = provider.loadDataRepresentation(for: UTType.image) { data, error in
                guard let data else {
                    LMKLogger.warning("LMKPhotoMetadata: loading the image data failed; reading no metadata", error: error, category: .lumiKit)
                    continuation.resume(returning: .empty)
                    return
                }
                continuation.resume(returning: read(from: data))
            }
        }
    }

    // MARK: - Writing

    /// A copy of `data` with `date` written to the EXIF capture dates (`DateTimeOriginal` and
    /// `DateTimeDigitized`, with their subsecond and time-zone offset tags, so the instant is
    /// unambiguous wherever the file is read) and `coordinate` to the GPS tags. A `nil` field
    /// leaves what the file already carries.
    ///
    /// The encoded pixels are copied through untouched (every frame, and a gain map where the
    /// file has one). Only when ImageIO cannot copy the container does the write fall back to
    /// re-encoding the first image at maximum quality; that fallback is logged.
    ///
    /// - Returns: `nil` when the bytes are not an image or the write fails.
    public static func write(date: Date?, coordinate: CLLocationCoordinate2D?, to data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            LMKLogger.warning("LMKPhotoMetadata: write failed: \(data.count) bytes are not an image", category: .lumiKit)
            return nil
        }
        return write(date: date, coordinate: coordinate, source: source)
    }

    /// `write(date:coordinate:to:)` for a file, rewritten in place through an atomic write. The
    /// file is left as it was when the bytes are not an image or the write fails (the error is
    /// thrown), so an original is never replaced by a broken or re-encoded copy silently.
    public static func write(date: Date?, coordinate: CLLocationCoordinate2D?, to fileURL: URL) throws {
        let data = try Data(contentsOf: fileURL)
        guard let stamped = write(date: date, coordinate: coordinate, to: data) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try stamped.write(to: fileURL, options: .atomic)
    }

    /// `write(date:coordinate:to:)` with this value's date and coordinate.
    public func writing(to data: Data) -> Data? {
        Self.write(date: date, coordinate: coordinate, to: data)
    }

    // MARK: - Internals

    private static var sourceOptions: CFDictionary { [kCGImageSourceShouldCache: false] as CFDictionary }

    private static func read(from source: CGImageSource) -> Self {
        var metadata = Self()
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            metadata.date = date(fromXMP: source)
            return metadata
        }
        metadata.date = date(fromProperties: properties) ?? date(fromXMP: source)
        if let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
            metadata.coordinate = coordinate(from: gps)
        }
        if let raw = properties[kCGImagePropertyOrientation as String] as? UInt32, let orientation = CGImagePropertyOrientation(rawValue: raw) {
            metadata.orientation = orientation
        }
        if let width = properties[kCGImagePropertyPixelWidth as String] as? CGFloat, let height = properties[kCGImagePropertyPixelHeight as String] as? CGFloat {
            switch metadata.orientation {
            case .left, .leftMirrored, .right, .rightMirrored:
                metadata.pixelSize = CGSize(width: height, height: width)
            default:
                metadata.pixelSize = CGSize(width: width, height: height)
            }
        }
        return metadata
    }

    /// The tags a write sets, grouped by ImageIO property dictionary (EXIF, GPS).
    private static func tags(date: Date?, coordinate: CLLocationCoordinate2D?) -> [CFString: [CFString: Any]] {
        var tags: [CFString: [CFString: Any]] = [:]
        if let date {
            let wallTime = makeEXIFDateFormatter().string(from: date)
            let subseconds = subsecondString(for: date)
            let offset = offsetString(for: date)
            tags[kCGImagePropertyExifDictionary] = [
                kCGImagePropertyExifDateTimeOriginal: wallTime,
                kCGImagePropertyExifDateTimeDigitized: wallTime,
                kCGImagePropertyExifSubsecTimeOriginal: subseconds,
                kCGImagePropertyExifSubsecTimeDigitized: subseconds,
                kCGImagePropertyExifOffsetTimeOriginal: offset,
                kCGImagePropertyExifOffsetTimeDigitized: offset,
            ]
        }
        if let coordinate, CLLocationCoordinate2DIsValid(coordinate) {
            tags[kCGImagePropertyGPSDictionary] = [
                kCGImagePropertyGPSLatitude: abs(coordinate.latitude),
                kCGImagePropertyGPSLatitudeRef: coordinate.latitude >= 0 ? "N" : "S",
                kCGImagePropertyGPSLongitude: abs(coordinate.longitude),
                kCGImagePropertyGPSLongitudeRef: coordinate.longitude >= 0 ? "E" : "W",
            ]
        }
        return tags
    }

    private static func write(date: Date?, coordinate: CLLocationCoordinate2D?, source: CGImageSource) -> Data? {
        guard let uti = CGImageSourceGetType(source) else {
            LMKLogger.warning("LMKPhotoMetadata: write failed: the source has no type identifier", category: .lumiKit)
            return nil
        }
        let tags = tags(date: date, coordinate: coordinate)
        if let copied = copyingSource(source, type: uti, merging: tags) {
            return copied
        }
        return reencodingSource(source, type: uti, merging: tags)
    }

    /// The container copied through with `tags` merged into its metadata: the encoded pixels,
    /// every frame, and the rest of the metadata stay as they were. `nil` when ImageIO cannot
    /// copy this container.
    private static func copyingSource(_ source: CGImageSource, type: CFString, merging tags: [CFString: [CFString: Any]]) -> Data? {
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, type, max(1, CGImageSourceGetCount(source)), nil) else { return nil }
        let metadata = CGImageMetadataCreateMutable()
        for (dictionary, values) in tags {
            for (key, value) in values {
                guard CGImageMetadataSetValueMatchingImageProperty(metadata, dictionary, key, value as CFTypeRef) else {
                    LMKLogger.warning("LMKPhotoMetadata: tag \(key) has no XMP counterpart; re-encoding to write it", category: .lumiKit)
                    return nil
                }
            }
        }
        let options: [CFString: Any] = [kCGImageDestinationMetadata: metadata, kCGImageDestinationMergeMetadata: true]
        var error: Unmanaged<CFError>?
        guard CGImageDestinationCopyImageSource(destination, source, options as CFDictionary, &error) else {
            LMKLogger.warning(
                "LMKPhotoMetadata: \(type) could not be copied through; re-encoding the first image",
                error: error?.takeRetainedValue(),
                category: .lumiKit
            )
            return nil
        }
        return output as Data
    }

    /// The fallback: the first image re-encoded at maximum quality (a gain map preserved) with
    /// `tags` merged into its property dictionaries.
    private static func reencodingSource(_ source: CGImageSource, type: CFString, merging tags: [CFString: [CFString: Any]]) -> Data? {
        var properties = (CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]) ?? [:]
        for (dictionary, values) in tags {
            var group = (properties[dictionary] as? [CFString: Any]) ?? [:]
            for (key, value) in values {
                group[key] = value
            }
            properties[dictionary] = group
        }
        properties[kCGImageDestinationLossyCompressionQuality] = 1.0
        properties[kCGImageDestinationPreserveGainMap] = true
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, type, 1, nil) else {
            LMKLogger.warning("LMKPhotoMetadata: write failed: ImageIO cannot encode \(type)", category: .lumiKit)
            return nil
        }
        CGImageDestinationAddImageFromSource(destination, source, 0, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            let width = properties[kCGImagePropertyPixelWidth] as? Int ?? 0
            let height = properties[kCGImagePropertyPixelHeight] as? Int ?? 0
            LMKLogger.warning("LMKPhotoMetadata: write failed: re-encoding a \(width)x\(height) \(type) image did not finalize", category: .lumiKit)
            return nil
        }
        return output as Data
    }

    // MARK: Dates

    /// A thread-local EXIF date formatter (`DateFormatter` is not thread-safe, so one per call).
    /// Wall time in the device's zone; the offset tags carry the zone.
    private static func makeEXIFDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }

    /// EXIF `SubsecTime`: the fraction of a second as decimal digits ("250" is a quarter second).
    private static func subsecondString(for date: Date) -> String {
        let fraction = date.timeIntervalSince1970 - date.timeIntervalSince1970.rounded(.down)
        return String(format: "%03d", Int((fraction * 1000).rounded(.down)))
    }

    /// EXIF `OffsetTime`: the device zone's UTC offset at `date`, as `±HH:MM`.
    private static func offsetString(for date: Date) -> String {
        let seconds = TimeZone.current.secondsFromGMT(for: date)
        let magnitude = abs(seconds)
        return String(format: "%@%02d:%02d", seconds < 0 ? "-" : "+", magnitude / 3600, magnitude % 3600 / 60)
    }

    /// The seconds from GMT in an EXIF `OffsetTime` (`±HH:MM`); `nil` for anything else.
    private static func secondsFromGMT(offset: String) -> Int? {
        let parts = offset.dropFirst().split(separator: ":", omittingEmptySubsequences: false)
        guard let sign = offset.first, sign == "+" || sign == "-", parts.count == 2,
              let hours = Int(parts[0]), let minutes = Int(parts[1]), hours < 24, minutes < 60 else { return nil }
        return (sign == "-" ? -1 : 1) * (hours * 3600 + minutes * 60)
    }

    /// An EXIF wall time made an instant: in the zone its `offset` tag names when the file has
    /// one (the device zone otherwise), plus the `subseconds` tag.
    private static func exifDate(_ wallTime: String, offset: String?, subseconds: String?) -> Date? {
        let formatter = makeEXIFDateFormatter()
        if let offset, let seconds = secondsFromGMT(offset: offset), let zone = TimeZone(secondsFromGMT: seconds) {
            formatter.timeZone = zone
        }
        guard let date = formatter.date(from: wallTime) else { return nil }
        guard let subseconds, !subseconds.isEmpty, subseconds.allSatisfy(\.isNumber), let fraction = Double("0." + subseconds) else { return date }
        return date.addingTimeInterval(fraction)
    }

    /// Tried in capture-fidelity order: EXIF `DateTimeOriginal`, EXIF `DateTimeDigitized`
    /// (scanned film), TIFF `DateTime` (last modification), IPTC `DateCreated` + `TimeCreated`
    /// (editorial stamping that often survives an EXIF strip), IPTC digital creation.
    private static func date(fromProperties metadata: [String: Any]) -> Date? {
        let exif = metadata[kCGImagePropertyExifDictionary as String] as? [String: Any]
        if let exif {
            if let original = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String,
               let date = exifDate(original, offset: exif[kCGImagePropertyExifOffsetTimeOriginal as String] as? String, subseconds: exif[kCGImagePropertyExifSubsecTimeOriginal as String] as? String) {
                return date
            }
            if let digitized = exif[kCGImagePropertyExifDateTimeDigitized as String] as? String,
               let date = exifDate(
                   digitized,
                   offset: exif[kCGImagePropertyExifOffsetTimeDigitized as String] as? String,
                   subseconds: exif[kCGImagePropertyExifSubsecTimeDigitized as String] as? String
               ) {
                return date
            }
        }

        if let tiff = metadata[kCGImagePropertyTIFFDictionary as String] as? [String: Any],
           let dateTime = tiff[kCGImagePropertyTIFFDateTime as String] as? String,
           let date = exifDate(dateTime, offset: exif?[kCGImagePropertyExifOffsetTime as String] as? String, subseconds: exif?[kCGImagePropertyExifSubsecTime as String] as? String) {
            return date
        }

        if let iptc = metadata[kCGImagePropertyIPTCDictionary as String] as? [String: Any] {
            if let date = combineIPTCDateTime(
                date: iptc[kCGImagePropertyIPTCDateCreated as String] as? String,
                time: iptc[kCGImagePropertyIPTCTimeCreated as String] as? String
            ) {
                return date
            }
            if let date = combineIPTCDateTime(
                date: iptc[kCGImagePropertyIPTCDigitalCreationDate as String] as? String,
                time: iptc[kCGImagePropertyIPTCDigitalCreationTime as String] as? String
            ) {
                return date
            }
        }

        return nil
    }

    /// The XMP packet is the last fallback (Lightroom / Photoshop / Capture One exports keep it
    /// after stripping EXIF); it is not surfaced through the properties dictionary.
    private static func date(fromXMP source: CGImageSource) -> Date? {
        guard let metadata = CGImageSourceCopyMetadataAtIndex(source, 0, nil) else { return nil }
        let paths = ["xmp:CreateDate", "xmp:DateCreated", "xmp:ModifyDate", "photoshop:DateCreated"]
        for path in paths {
            guard let value = CGImageMetadataCopyStringValueWithPath(metadata, nil, path as CFString) as String?,
                  let date = parseXMPDateString(value) else { continue }
            return date
        }
        return nil
    }

    /// XMP dates follow ISO 8601 with optional fractional seconds and may be date-only.
    private static func parseXMPDateString(_ value: String) -> Date? {
        let dateTime = ISO8601DateFormatter()
        dateTime.formatOptions = [.withInternetDateTime]
        if let date = dateTime.date(from: value) { return date }

        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: value) { return date }

        let dateOnly = ISO8601DateFormatter()
        dateOnly.formatOptions = [.withFullDate]
        return dateOnly.date(from: value)
    }

    /// IPTC `YYYYMMDD` plus an optional `HHMMSS±HHMM` time; date-only when the time is missing or malformed.
    private static func combineIPTCDateTime(date: String?, time: String?) -> Date? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if let time {
            for format in ["yyyyMMddHHmmssZ", "yyyyMMddHHmmss"] {
                formatter.dateFormat = format
                if let parsed = formatter.date(from: date + time) { return parsed }
            }
        }
        formatter.dateFormat = "yyyyMMdd"
        return formatter.date(from: date)
    }

    // MARK: GPS

    private static func coordinate(from gps: [String: Any]) -> CLLocationCoordinate2D? {
        guard let latitude = gps[kCGImagePropertyGPSLatitude as String] as? Double,
              let longitude = gps[kCGImagePropertyGPSLongitude as String] as? Double,
              let latRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String,
              let lonRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String else {
            return nil
        }
        let coordinate = CLLocationCoordinate2D(
            latitude: latRef == "S" ? -latitude : latitude,
            longitude: lonRef == "W" ? -longitude : longitude
        )
        guard CLLocationCoordinate2DIsValid(coordinate) else { return nil }
        return coordinate
    }
}
