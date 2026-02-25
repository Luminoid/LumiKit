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
    // MARK: - Cached Formatters

    private static let exifDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    // MARK: - Date Extraction

    /// Extract date from image EXIF data.
    ///
    /// Checks `DateTimeOriginal` (EXIF) and `DateTime` (TIFF) fields.
    /// For photos from `PHPickerViewController`, prefer the async `extractDate(from:)` variant
    /// which uses `loadDataRepresentation` to preserve EXIF metadata.
    ///
    /// - Parameters:
    ///   - image: Source image.
    ///   - imageData: Optional pre-encoded image data (avoids re-encoding).
    /// - Returns: The extracted date, or `nil` if no EXIF date is present.
    public static func extractDate(from image: UIImage, imageData: Data? = nil) -> Date? {
        guard let data = imageData ?? image.pngData() ?? image.jpegData(compressionQuality: 1.0) else { return nil }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return nil
        }

        let formatter = exifDateFormatter

        // Try EXIF DateTimeOriginal
        if let exif = metadata[kCGImagePropertyExifDictionary as String] as? [String: Any],
           let dateTimeOriginal = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String,
           let date = formatter.date(from: dateTimeOriginal) {
            return date
        }

        // Try TIFF DateTime
        if let tiff = metadata[kCGImagePropertyTIFFDictionary as String] as? [String: Any],
           let dateTime = tiff[kCGImagePropertyTIFFDateTime as String] as? String,
           let date = formatter.date(from: dateTime) {
            return date
        }

        return nil
    }

    /// Extract date from a `PHPickerResult`.
    ///
    /// Uses `loadDataRepresentation` to get raw image bytes with EXIF metadata intact,
    /// then extracts `DateTimeOriginal` or `DateTime` from the metadata.
    /// - Parameter result: Picker result from `PHPickerViewController`.
    /// - Returns: The extracted date, or `nil`.
    public static func extractDate(from result: PHPickerResult) async -> Date? {
        await withCheckedContinuation { continuation in
            result.itemProvider.loadDataRepresentation(forTypeIdentifier: "public.image") { data, _ in
                guard let data,
                      let source = CGImageSourceCreateWithData(data as CFData, nil),
                      let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
                    continuation.resume(returning: nil)
                    return
                }

                let formatter = exifDateFormatter

                // Try EXIF DateTimeOriginal
                if let exif = metadata[kCGImagePropertyExifDictionary as String] as? [String: Any],
                   let dateTimeOriginal = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String,
                   let date = formatter.date(from: dateTimeOriginal) {
                    continuation.resume(returning: date)
                    return
                }

                // Try TIFF DateTime
                if let tiff = metadata[kCGImagePropertyTIFFDictionary as String] as? [String: Any],
                   let dateTime = tiff[kCGImagePropertyTIFFDateTime as String] as? String,
                   let date = formatter.date(from: dateTime) {
                    continuation.resume(returning: date)
                    return
                }

                continuation.resume(returning: nil)
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
            result.itemProvider.loadDataRepresentation(forTypeIdentifier: "public.image") { data, _ in
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
