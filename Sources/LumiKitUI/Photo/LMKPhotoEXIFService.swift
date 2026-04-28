//
//  LMKPhotoEXIFService.swift
//  LumiKit
//
//  Extracts date and GPS location from photo EXIF metadata.
//

import CoreLocation
import ImageIO
@preconcurrency import PhotosUI
import UIKit
import UniformTypeIdentifiers

/// Extracts date and GPS coordinates from photo EXIF metadata.
///
/// Extract date from an image:
/// ```swift
/// let date = LMKPhotoEXIFService.extractDate(from: image)
/// ```
///
/// Extract location from a picker result:
/// ```swift
/// let coordinate = await LMKPhotoEXIFService.extractLocation(from: pickerResult)
/// ```
public nonisolated enum LMKPhotoEXIFService {
    // MARK: - Date Extraction

    /// Create a thread-local EXIF date formatter.
    /// `DateFormatter` is not thread-safe, so a new instance is created per call.
    private static func makeEXIFDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }

    /// Extract a date from EXIF / TIFF / IPTC metadata dictionaries.
    ///
    /// Tried in capture-fidelity order:
    /// 1. EXIF `DateTimeOriginal` — when the shutter clicked
    /// 2. EXIF `DateTimeDigitized` — when the image was digitized (often
    ///    equal to original; useful for scanned film)
    /// 3. TIFF `DateTime` — last modification time
    /// 4. IPTC `DateCreated` / `TimeCreated` — editorial date stamping
    ///    (often present on photos imported from professional workflows
    ///    even after EXIF is stripped)
    /// 5. IPTC `DigitalCreationDate` / `DigitalCreationTime`
    ///
    /// - Parameter metadata: The image metadata dictionary from `CGImageSourceCopyPropertiesAtIndex`.
    /// - Returns: The extracted date, or `nil` if no date field is present.
    private static func extractDateFromMetadata(_ metadata: [String: Any]) -> Date? {
        let formatter = makeEXIFDateFormatter()

        if let exif = metadata[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            if let original = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String,
               let date = formatter.date(from: original) {
                return date
            }
            if let digitized = exif[kCGImagePropertyExifDateTimeDigitized as String] as? String,
               let date = formatter.date(from: digitized) {
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

    /// Extract a date from the image's XMP packet — the last fallback
    /// for photos exported from Lightroom / Photoshop / Capture One,
    /// where the XMP block survives even when EXIF is stripped. Reads
    /// `xmp:CreateDate`, `xmp:DateCreated`, `xmp:ModifyDate`, and
    /// `photoshop:DateCreated` in priority order.
    private static func extractDateFromXMP(_ source: CGImageSource) -> Date? {
        guard let metadata = CGImageSourceCopyMetadataAtIndex(source, 0, nil) else { return nil }
        let paths = [
            "xmp:CreateDate",
            "xmp:DateCreated",
            "xmp:ModifyDate",
            "photoshop:DateCreated",
        ]
        for path in paths {
            guard let value = CGImageMetadataCopyStringValueWithPath(
                metadata, nil, path as CFString
            ) as String?, let date = parseXMPDateString(value) else { continue }
            return date
        }
        return nil
    }

    /// XMP dates follow ISO 8601 with optional fractional seconds and may
    /// be date-only on some Photoshop exports.
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

    /// Combine an IPTC date string (`YYYYMMDD`) with an optional time
    /// string (`HHMMSS±HHMM`) into a single `Date`. Falls back to a
    /// date-only parse when the time string is missing or malformed.
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

    /// Try the standard properties dictionary (EXIF / TIFF / IPTC) first,
    /// then fall through to the XMP packet — XMP is queried via a
    /// separate ImageIO API and not surfaced through the properties dict.
    private static func extractDate(fromImageSource source: CGImageSource) -> Date? {
        if let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
           let date = extractDateFromMetadata(metadata) {
            return date
        }
        return extractDateFromXMP(source)
    }

    /// Extract date from image EXIF data.
    ///
    /// Walks EXIF, TIFF, IPTC, and XMP date fields in capture-fidelity
    /// order so photos with stripped EXIF (screenshots, edited exports)
    /// can still surface a meaningful date when one of the other
    /// containers has it.
    /// For photos from `PHPickerViewController`, prefer the async
    /// `extractDate(from:)` variant which uses `loadDataRepresentation`
    /// to preserve metadata across the pick.
    ///
    /// - Parameters:
    ///   - image: Source image.
    ///   - imageData: Optional pre-encoded image data (avoids re-encoding).
    /// - Returns: The extracted date, or `nil` if no date field is present.
    public static func extractDate(from image: UIImage, imageData: Data? = nil) -> Date? {
        guard let data = imageData ?? image.pngData() ?? image.jpegData(compressionQuality: 1.0) else { return nil }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return extractDate(fromImageSource: source)
    }

    /// Extract date from a `PHPickerResult`.
    ///
    /// Uses `loadDataRepresentation` to get raw image bytes with metadata
    /// intact, then walks EXIF, TIFF, IPTC, and XMP date fields.
    /// - Parameter result: Picker result from `PHPickerViewController`.
    /// - Returns: The extracted date, or `nil`.
    public static func extractDate(from result: PHPickerResult) async -> Date? {
        await withCheckedContinuation { continuation in
            _ = result.itemProvider.loadDataRepresentation(for: UTType.image) { data, _ in
                guard let data,
                      let source = CGImageSourceCreateWithData(data as CFData, nil) else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: extractDate(fromImageSource: source))
            }
        }
    }

    // MARK: - GPS Location Extraction

    /// Parse GPS coordinates from a GPS metadata dictionary.
    private static func parseGPSCoordinate(from gps: [String: Any]) -> CLLocationCoordinate2D? {
        guard let latitude = gps[kCGImagePropertyGPSLatitude as String] as? Double,
              let longitude = gps[kCGImagePropertyGPSLongitude as String] as? Double,
              let latRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String,
              let lonRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String else {
            return nil
        }

        let lat = latRef == "S" ? -latitude : latitude
        let lon = lonRef == "W" ? -longitude : longitude
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)

        guard CLLocationCoordinate2DIsValid(coordinate) else { return nil }
        return coordinate
    }

    /// Extract GPS coordinates from image EXIF data.
    ///
    /// Reads the GPS dictionary from EXIF metadata and converts latitude/longitude
    /// with N/S/E/W reference directions.
    ///
    /// - Parameters:
    ///   - image: Source image.
    ///   - imageData: Optional pre-encoded image data (avoids re-encoding).
    /// - Returns: Valid coordinates, or `nil` if no GPS data is present.
    public static func extractLocation(from image: UIImage, imageData: Data? = nil) -> CLLocationCoordinate2D? {
        guard let data = imageData ?? image.jpegData(compressionQuality: 1.0) ?? image.pngData() else { return nil }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
              let gps = metadata[kCGImagePropertyGPSDictionary as String] as? [String: Any] else {
            return nil
        }

        return parseGPSCoordinate(from: gps)
    }

    /// Extract GPS coordinates from a `PHPickerResult`.
    ///
    /// Uses `loadDataRepresentation` to get raw image bytes and extracts GPS data from EXIF metadata.
    /// - Parameter result: Picker result from `PHPickerViewController`.
    /// - Returns: Valid coordinates, or `nil`.
    public static func extractLocation(from result: PHPickerResult) async -> CLLocationCoordinate2D? {
        await withCheckedContinuation { continuation in
            _ = result.itemProvider.loadDataRepresentation(for: UTType.image) { data, _ in
                guard let data,
                      let source = CGImageSourceCreateWithData(data as CFData, nil),
                      let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
                      let gps = metadata[kCGImagePropertyGPSDictionary as String] as? [String: Any] else {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: parseGPSCoordinate(from: gps))
            }
        }
    }
}
