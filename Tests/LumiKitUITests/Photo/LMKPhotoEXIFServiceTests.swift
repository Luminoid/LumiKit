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

@Suite("LMKPhotoEXIFService")
@MainActor
struct LMKPhotoEXIFServiceTests {
    // MARK: - Date Extraction

    @Test("extractDate returns nil for image without EXIF")
    func extractDateReturnsNilForPlainImage() {
        let image = UIImage.lmk_solidColor(.red, size: CGSize(width: 10, height: 10))
        let date = LMKPhotoEXIFService.extractDate(from: image)
        #expect(date == nil)
    }

    @Test("extractDate accepts optional imageData parameter")
    func extractDateAcceptsImageData() {
        let image = UIImage.lmk_solidColor(.red, size: CGSize(width: 10, height: 10))
        let data = image.pngData()
        let date = LMKPhotoEXIFService.extractDate(from: image, imageData: data)
        // No EXIF data in a solid-color image
        #expect(date == nil)
    }

    // MARK: - Location Extraction

    @Test("extractLocation returns nil for image without GPS")
    func extractLocationReturnsNilForPlainImage() {
        let image = UIImage.lmk_solidColor(.blue, size: CGSize(width: 10, height: 10))
        let location = LMKPhotoEXIFService.extractLocation(from: image)
        #expect(location == nil)
    }

    @Test("extractLocation accepts optional imageData parameter")
    func extractLocationAcceptsImageData() {
        let image = UIImage.lmk_solidColor(.blue, size: CGSize(width: 10, height: 10))
        let data = image.jpegData(compressionQuality: 1.0)
        let location = LMKPhotoEXIFService.extractLocation(from: image, imageData: data)
        #expect(location == nil)
    }

    // MARK: - Coordinate Validation

    @Test("CLLocationCoordinate2D validation works correctly")
    func coordinateValidation() {
        let validCoord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        #expect(CLLocationCoordinate2DIsValid(validCoord))

        let invalidCoord = CLLocationCoordinate2D(latitude: 91.0, longitude: 0.0)
        #expect(!CLLocationCoordinate2DIsValid(invalidCoord))

        let invalidCoord2 = CLLocationCoordinate2D(latitude: 0.0, longitude: 181.0)
        #expect(!CLLocationCoordinate2DIsValid(invalidCoord2))
    }

    // MARK: - EXIF Date Extraction

    @Test("extractDate extracts DateTimeOriginal from EXIF")
    func extractDateFromEXIFDateTimeOriginal() {
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

    @Test("extractDate returns nil for malformed date string")
    func extractDateReturnsNilForMalformedDate() {
        let image = UIImage.lmk_solidColor(.purple, size: CGSize(width: 10, height: 10))
        let badDate = "invalid-date-format"
        let imageData = createImageDataWithEXIF(image: image, dateTimeOriginal: badDate)

        let extractedDate = LMKPhotoEXIFService.extractDate(from: image, imageData: imageData)

        #expect(extractedDate == nil)
    }

    // MARK: - GPS Location Extraction

    @Test("extractLocation extracts Northern/Eastern coordinates")
    func extractLocationNorthernEastern() {
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
        #expect(abs(coordinate!.latitude - 35.6762) < 0.001)
        #expect(abs(coordinate!.longitude - 139.6503) < 0.001)
    }

    @Test("extractLocation extracts Southern/Western coordinates")
    func extractLocationSouthernWestern() {
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
        #expect(abs(coordinate!.latitude - (-33.8688)) < 0.001)
        // Longitude should be negative (West)
        #expect(abs(coordinate!.longitude - (-151.2093)) < 0.001)
    }

    @Test("extractLocation handles mixed hemisphere (N/W)")
    func extractLocationMixedHemisphere() {
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
        #expect(abs(coordinate!.latitude - 37.7749) < 0.001)
        #expect(abs(coordinate!.longitude - (-122.4194)) < 0.001)
    }

    @Test("extractLocation returns nil for invalid coordinates")
    func extractLocationReturnsNilForInvalidCoordinates() {
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
    guard let cgImage = image.cgImage else { return nil }

    let mutableData = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(mutableData, UTType.jpeg.identifier as CFString, 1, nil) else {
        return nil
    }

    let exifDict: [String: Any] = [
        kCGImagePropertyExifDateTimeOriginal as String: dateTimeOriginal
    ]
    let metadata: [String: Any] = [
        kCGImagePropertyExifDictionary as String: exifDict
    ]

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
    guard let cgImage = image.cgImage else { return nil }

    let mutableData = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(mutableData, UTType.jpeg.identifier as CFString, 1, nil) else {
        return nil
    }

    let gpsDict: [String: Any] = [
        kCGImagePropertyGPSLatitude as String: latitude,
        kCGImagePropertyGPSLongitude as String: longitude,
        kCGImagePropertyGPSLatitudeRef as String: latRef,
        kCGImagePropertyGPSLongitudeRef as String: lonRef
    ]
    let metadata: [String: Any] = [
        kCGImagePropertyGPSDictionary as String: gpsDict
    ]

    CGImageDestinationAddImage(destination, cgImage, metadata as CFDictionary)
    CGImageDestinationFinalize(destination)

    return mutableData as Data
}
