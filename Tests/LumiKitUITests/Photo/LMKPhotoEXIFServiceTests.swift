//
//  LMKPhotoEXIFServiceTests.swift
//  LumiKit
//

import CoreLocation
import Testing
import UIKit

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
}
