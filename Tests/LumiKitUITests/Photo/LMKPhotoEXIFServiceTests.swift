//
//  LMKPhotoEXIFServiceTests.swift
//  LumiKit
//

import CoreLocation
import ImageIO
import Testing
import UIKit
import UniformTypeIdentifiers
@testable import LumiKitUI

@MainActor
struct LMKPhotoEXIFServiceTests {
    // MARK: - Date Extraction

    @Test
    func `extractDate returns nil for image without EXIF`() {
        let image = UIImage.lmk_solidColor(.red, size: CGSize(width: 10, height: 10))
        let date = LMKPhotoEXIFService.extractDate(from: image)
        #expect(date == nil)
    }

    @Test
    func `extractDate accepts optional imageData parameter`() {
        let image = UIImage.lmk_solidColor(.red, size: CGSize(width: 10, height: 10))
        let data = image.pngData()
        let date = LMKPhotoEXIFService.extractDate(from: image, imageData: data)
        // No EXIF data in a solid-color image
        #expect(date == nil)
    }

    // MARK: - Location Extraction

    @Test
    func `extractLocation returns nil for image without GPS`() {
        let image = UIImage.lmk_solidColor(.blue, size: CGSize(width: 10, height: 10))
        let location = LMKPhotoEXIFService.extractLocation(from: image)
        #expect(location == nil)
    }

    @Test
    func `extractLocation accepts optional imageData parameter`() {
        let image = UIImage.lmk_solidColor(.blue, size: CGSize(width: 10, height: 10))
        let data = image.jpegData(compressionQuality: 1.0)
        let location = LMKPhotoEXIFService.extractLocation(from: image, imageData: data)
        #expect(location == nil)
    }

    // MARK: - Coordinate Validation

    @Test
    func `CLLocationCoordinate2D validation works correctly`() {
        let validCoord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        #expect(CLLocationCoordinate2DIsValid(validCoord))

        let invalidCoord = CLLocationCoordinate2D(latitude: 91.0, longitude: 0.0)
        #expect(!CLLocationCoordinate2DIsValid(invalidCoord))

        let invalidCoord2 = CLLocationCoordinate2D(latitude: 0.0, longitude: 181.0)
        #expect(!CLLocationCoordinate2DIsValid(invalidCoord2))
    }

    // MARK: - EXIF Date Extraction

    @Test
    func `extractDate extracts DateTimeOriginal from EXIF`() {
        let image = UIImage.lmk_solidColor(.green, size: CGSize(width: 10, height: 10))
        let exifDate = "2024:03:15 14:30:45"
        let imageData = createImageDataWithEXIF(image: image, dateTimeOriginal: exifDate)

        let extractedDate = LMKPhotoEXIFService.extractDate(from: image, imageData: imageData)

        #expect(extractedDate != nil)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let expectedDate = formatter.date(from: exifDate)
        #expect(extractedDate == expectedDate)
    }

    @Test
    func `extractDate returns nil for malformed date string`() {
        let image = UIImage.lmk_solidColor(.purple, size: CGSize(width: 10, height: 10))
        let badDate = "invalid-date-format"
        let imageData = createImageDataWithEXIF(image: image, dateTimeOriginal: badDate)

        let extractedDate = LMKPhotoEXIFService.extractDate(from: image, imageData: imageData)

        #expect(extractedDate == nil)
    }

    @Test
    func `extractDate falls back to EXIF DateTimeDigitized when DateTimeOriginal is absent`() {
        let image = UIImage.lmk_solidColor(.yellow, size: CGSize(width: 10, height: 10))
        let digitized = "2023:11:09 08:15:00"
        let imageData = createImageDataWithEXIF(image: image, dateTimeDigitized: digitized)

        let extractedDate = LMKPhotoEXIFService.extractDate(from: image, imageData: imageData)

        #expect(extractedDate != nil)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        #expect(extractedDate == formatter.date(from: digitized))
    }

    @Test
    func `extractDate falls back to TIFF DateTime when no EXIF dates`() {
        let image = UIImage.lmk_solidColor(.gray, size: CGSize(width: 10, height: 10))
        let tiffDate = "2024:07:20 11:00:00"
        let imageData = createImageDataWithTIFF(image: image, dateTime: tiffDate)

        let extractedDate = LMKPhotoEXIFService.extractDate(from: image, imageData: imageData)

        #expect(extractedDate != nil)
    }

    @Test
    func `extractDate falls back to IPTC DateCreated + TimeCreated when EXIF and TIFF are absent`() {
        let image = UIImage.lmk_solidColor(.systemPink, size: CGSize(width: 10, height: 10))
        // 2024-06-15 14:30:00, IPTC date YYYYMMDD + time HHMMSS
        let imageData = createImageDataWithIPTC(
            image: image,
            dateCreated: "20240615",
            timeCreated: "143000"
        )

        let extractedDate = LMKPhotoEXIFService.extractDate(from: image, imageData: imageData)

        #expect(extractedDate != nil)
    }

    @Test
    func `extractDate falls back to IPTC date-only when time is missing`() {
        let image = UIImage.lmk_solidColor(.systemTeal, size: CGSize(width: 10, height: 10))
        let imageData = createImageDataWithIPTC(image: image, dateCreated: "20240615", timeCreated: nil)

        let extractedDate = LMKPhotoEXIFService.extractDate(from: image, imageData: imageData)

        #expect(extractedDate != nil)
    }

    // MARK: - GPS Location Extraction

    @Test
    func `extractLocation extracts Northern/Eastern coordinates`() throws {
        let image = UIImage.lmk_solidColor(.cyan, size: CGSize(width: 10, height: 10))
        // Tokyo coordinates (N, E)
        let imageData = createImageDataWithGPS(
            image: image,
            latitude: 35.6762,
            longitude: 139.6503,
            latRef: "N",
            lonRef: "E"
        )

        let coordinate = LMKPhotoEXIFService.extractLocation(from: image, imageData: imageData)

        #expect(coordinate != nil)
        #expect(try abs(#require(coordinate?.latitude) - 35.6762) < 0.001)
        #expect(try abs(#require(coordinate?.longitude) - 139.6503) < 0.001)
    }

    @Test
    func `extractLocation extracts Southern/Western coordinates`() throws {
        let image = UIImage.lmk_solidColor(.orange, size: CGSize(width: 10, height: 10))
        // Sydney coordinates (S, E) but test with W for coverage
        let imageData = createImageDataWithGPS(
            image: image,
            latitude: 33.8688,
            longitude: 151.2093,
            latRef: "S",
            lonRef: "W"
        )

        let coordinate = LMKPhotoEXIFService.extractLocation(from: image, imageData: imageData)

        #expect(coordinate != nil)
        // Latitude should be negative (South)
        #expect(try abs(#require(coordinate?.latitude) - -33.8688) < 0.001)
        // Longitude should be negative (West)
        #expect(try abs(#require(coordinate?.longitude) - -151.2093) < 0.001)
    }

    @Test
    func `extractLocation handles mixed hemisphere (N/W)`() throws {
        let image = UIImage.lmk_solidColor(.magenta, size: CGSize(width: 10, height: 10))
        // San Francisco coordinates (N, W)
        let imageData = createImageDataWithGPS(
            image: image,
            latitude: 37.7749,
            longitude: 122.4194,
            latRef: "N",
            lonRef: "W"
        )

        let coordinate = LMKPhotoEXIFService.extractLocation(from: image, imageData: imageData)

        #expect(coordinate != nil)
        #expect(try abs(#require(coordinate?.latitude) - 37.7749) < 0.001)
        #expect(try abs(#require(coordinate?.longitude) - -122.4194) < 0.001)
    }

    @Test
    func `extractLocation returns nil for invalid coordinates`() {
        let image = UIImage.lmk_solidColor(.brown, size: CGSize(width: 10, height: 10))
        // Invalid latitude (> 90)
        let imageData = createImageDataWithGPS(
            image: image,
            latitude: 95.0,
            longitude: 0.0,
            latRef: "N",
            lonRef: "E"
        )

        let coordinate = LMKPhotoEXIFService.extractLocation(from: image, imageData: imageData)

        #expect(coordinate == nil)
    }
}

// MARK: - Test Helpers

/// Create image data with EXIF DateTimeOriginal metadata.
private func createImageDataWithEXIF(image: UIImage, dateTimeOriginal: String) -> Data? {
    encodeJPEGWithMetadata(image: image, metadata: [
        kCGImagePropertyExifDictionary as String: [
            kCGImagePropertyExifDateTimeOriginal as String: dateTimeOriginal,
        ],
    ])
}

/// Create image data with only EXIF DateTimeDigitized (no DateTimeOriginal).
private func createImageDataWithEXIF(image: UIImage, dateTimeDigitized: String) -> Data? {
    encodeJPEGWithMetadata(image: image, metadata: [
        kCGImagePropertyExifDictionary as String: [
            kCGImagePropertyExifDateTimeDigitized as String: dateTimeDigitized,
        ],
    ])
}

/// Create image data with only the TIFF DateTime field.
private func createImageDataWithTIFF(image: UIImage, dateTime: String) -> Data? {
    encodeJPEGWithMetadata(image: image, metadata: [
        kCGImagePropertyTIFFDictionary as String: [
            kCGImagePropertyTIFFDateTime as String: dateTime,
        ],
    ])
}

/// Create image data with IPTC DateCreated (and optional TimeCreated) only.
private func createImageDataWithIPTC(image: UIImage, dateCreated: String, timeCreated: String?) -> Data? {
    var iptc: [String: Any] = [kCGImagePropertyIPTCDateCreated as String: dateCreated]
    if let timeCreated {
        iptc[kCGImagePropertyIPTCTimeCreated as String] = timeCreated
    }
    return encodeJPEGWithMetadata(image: image, metadata: [
        kCGImagePropertyIPTCDictionary as String: iptc,
    ])
}

private func encodeJPEGWithMetadata(image: UIImage, metadata: [String: Any]) -> Data? {
    guard let cgImage = image.cgImage else { return nil }
    let mutableData = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(
        mutableData, UTType.jpeg.identifier as CFString, 1, nil
    ) else { return nil }
    CGImageDestinationAddImage(destination, cgImage, metadata as CFDictionary)
    CGImageDestinationFinalize(destination)
    return mutableData as Data
}

/// Create image data with GPS coordinates.
private func createImageDataWithGPS(
    image: UIImage,
    latitude: Double,
    longitude: Double,
    latRef: String,
    lonRef: String
) -> Data? {
    encodeJPEGWithMetadata(image: image, metadata: [
        kCGImagePropertyGPSDictionary as String: [
            kCGImagePropertyGPSLatitude as String: latitude,
            kCGImagePropertyGPSLongitude as String: longitude,
            kCGImagePropertyGPSLatitudeRef as String: latRef,
            kCGImagePropertyGPSLongitudeRef as String: lonRef,
        ],
    ])
}
