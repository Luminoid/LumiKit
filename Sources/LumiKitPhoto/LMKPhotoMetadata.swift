//
//  LMKPhotoMetadata.swift
//  LumiKit
//
//  Reads the capture date, GPS coordinate, pixel size, and orientation out of
//  image bytes, and writes a date and coordinate back into them.
//

import CoreLocation
import ImageIO
import LumiKitUI
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
    /// The capture date, walking EXIF, TIFF, IPTC, and XMP in capture-fidelity order.
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
            _ = provider.loadDataRepresentation(for: UTType.image) { data, _ in
                guard let data else {
                    continuation.resume(returning: .empty)
                    return
                }
                continuation.resume(returning: read(from: data))
            }
        }
    }

    // MARK: - Writing

    /// A copy of `data` with `date` written to the EXIF and TIFF date fields and `coordinate` to
    /// the GPS dictionary. A `nil` field leaves what the file already carries. The pixels are
    /// copied through without re-encoding.
    ///
    /// - Returns: `nil` when the bytes are not an image or the write fails.
    public static func write(date: Date?, coordinate: CLLocationCoordinate2D?, to data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return write(date: date, coordinate: coordinate, source: source)
    }

    /// `write(date:coordinate:to:)` for a file, rewritten in place.
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

    private static func write(date: Date?, coordinate: CLLocationCoordinate2D?, source: CGImageSource) -> Data? {
        guard let uti = CGImageSourceGetType(source) else { return nil }
        var properties = (CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]) ?? [:]

        if let date {
            let dateString = makeEXIFDateFormatter().string(from: date)
            var exif = (properties[kCGImagePropertyExifDictionary] as? [CFString: Any]) ?? [:]
            exif[kCGImagePropertyExifDateTimeOriginal] = dateString
            exif[kCGImagePropertyExifDateTimeDigitized] = dateString
            properties[kCGImagePropertyExifDictionary] = exif
            var tiff = (properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any]) ?? [:]
            tiff[kCGImagePropertyTIFFDateTime] = dateString
            properties[kCGImagePropertyTIFFDictionary] = tiff
        }

        if let coordinate, CLLocationCoordinate2DIsValid(coordinate) {
            var gps = (properties[kCGImagePropertyGPSDictionary] as? [CFString: Any]) ?? [:]
            gps[kCGImagePropertyGPSLatitude] = abs(coordinate.latitude)
            gps[kCGImagePropertyGPSLatitudeRef] = coordinate.latitude >= 0 ? "N" : "S"
            gps[kCGImagePropertyGPSLongitude] = abs(coordinate.longitude)
            gps[kCGImagePropertyGPSLongitudeRef] = coordinate.longitude >= 0 ? "E" : "W"
            properties[kCGImagePropertyGPSDictionary] = gps
        }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, uti, 1, nil) else { return nil }
        CGImageDestinationAddImageFromSource(destination, source, 0, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }

    // MARK: Dates

    /// A thread-local EXIF date formatter (`DateFormatter` is not thread-safe, so one per call).
    private static func makeEXIFDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }

    /// Tried in capture-fidelity order: EXIF `DateTimeOriginal`, EXIF `DateTimeDigitized`
    /// (scanned film), TIFF `DateTime` (last modification), IPTC `DateCreated` + `TimeCreated`
    /// (editorial stamping that often survives an EXIF strip), IPTC digital creation.
    private static func date(fromProperties metadata: [String: Any]) -> Date? {
        let formatter = makeEXIFDateFormatter()

        if let exif = metadata[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            if let original = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String, let date = formatter.date(from: original) {
                return date
            }
            if let digitized = exif[kCGImagePropertyExifDateTimeDigitized as String] as? String, let date = formatter.date(from: digitized) {
                return date
            }
        }

        if let tiff = metadata[kCGImagePropertyTIFFDictionary as String] as? [String: Any],
           let dateTime = tiff[kCGImagePropertyTIFFDateTime as String] as? String,
           let date = formatter.date(from: dateTime) {
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
