//
//  LMKPhotoMetadataTests.swift
//  LumiKit
//

import CoreLocation
import ImageIO
import LumiKitUI
import Testing
import UIKit
import UniformTypeIdentifiers
@testable import LumiKitPhoto

@MainActor
struct LMKPhotoMetadataTests {
    private func exifDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: string)
    }

    // MARK: - Reading

    @Test
    func `Plain image bytes carry size and orientation but no date or coordinate`() {
        let metadata = LMKPhotoMetadata.read(from: makeJPEG(width: 30, height: 20))
        #expect(metadata.date == nil)
        #expect(metadata.coordinate == nil)
        #expect(metadata.pixelSize == CGSize(width: 30, height: 20))
        #expect(metadata.orientation == .up)
    }

    @Test
    func `Non-image bytes read as empty`() {
        #expect(LMKPhotoMetadata.read(from: Data([1, 2, 3])) == .empty)
        #expect(LMKPhotoMetadata.read(from: URL(fileURLWithPath: "/nonexistent.jpg")) == .empty)
    }

    @Test
    func `Orientation swaps the reported pixel size`() {
        let metadata = LMKPhotoMetadata.read(from: makeJPEG(width: 30, height: 20, metadata: [
            kCGImagePropertyOrientation as String: CGImagePropertyOrientation.right.rawValue,
        ]))
        #expect(metadata.orientation == .right)
        #expect(metadata.pixelSize == CGSize(width: 20, height: 30))
    }

    @Test
    func `EXIF DateTimeOriginal wins`() {
        let data = makeJPEG(metadata: [
            kCGImagePropertyExifDictionary as String: [
                kCGImagePropertyExifDateTimeOriginal as String: "2024:03:15 14:30:45",
                kCGImagePropertyExifDateTimeDigitized as String: "2023:01:01 00:00:00",
            ],
        ])
        #expect(LMKPhotoMetadata.read(from: data).date == exifDate("2024:03:15 14:30:45"))
    }

    @Test
    func `A malformed EXIF date yields nil`() {
        let data = makeJPEG(metadata: [
            kCGImagePropertyExifDictionary as String: [kCGImagePropertyExifDateTimeOriginal as String: "invalid-date-format"],
        ])
        #expect(LMKPhotoMetadata.read(from: data).date == nil)
    }

    @Test
    func `Falls back to DateTimeDigitized, then TIFF, then IPTC`() {
        let digitized = makeJPEG(metadata: [
            kCGImagePropertyExifDictionary as String: [kCGImagePropertyExifDateTimeDigitized as String: "2023:11:09 08:15:00"],
        ])
        #expect(LMKPhotoMetadata.read(from: digitized).date == exifDate("2023:11:09 08:15:00"))

        let tiff = makeJPEG(metadata: [
            kCGImagePropertyTIFFDictionary as String: [kCGImagePropertyTIFFDateTime as String: "2024:07:20 11:00:00"],
        ])
        #expect(LMKPhotoMetadata.read(from: tiff).date != nil)

        let iptc = makeJPEG(metadata: [
            kCGImagePropertyIPTCDictionary as String: [
                kCGImagePropertyIPTCDateCreated as String: "20240615",
                kCGImagePropertyIPTCTimeCreated as String: "143000",
            ],
        ])
        #expect(LMKPhotoMetadata.read(from: iptc).date != nil)

        let dateOnly = makeJPEG(metadata: [
            kCGImagePropertyIPTCDictionary as String: [kCGImagePropertyIPTCDateCreated as String: "20240615"],
        ])
        #expect(LMKPhotoMetadata.read(from: dateOnly).date != nil)
    }

    @Test
    func `GPS references sign the coordinate`() throws {
        let tokyo = LMKPhotoMetadata.read(from: makeJPEG(gps: (35.6762, 139.6503, "N", "E")))
        #expect(try abs(#require(tokyo.coordinate?.latitude) - 35.6762) < 0.001)
        #expect(try abs(#require(tokyo.coordinate?.longitude) - 139.6503) < 0.001)

        let southWest = LMKPhotoMetadata.read(from: makeJPEG(gps: (33.8688, 151.2093, "S", "W")))
        #expect(try abs(#require(southWest.coordinate?.latitude) - -33.8688) < 0.001)
        #expect(try abs(#require(southWest.coordinate?.longitude) - -151.2093) < 0.001)

        let sanFrancisco = LMKPhotoMetadata.read(from: makeJPEG(gps: (37.7749, 122.4194, "N", "W")))
        #expect(try abs(#require(sanFrancisco.coordinate?.longitude) - -122.4194) < 0.001)
    }

    @Test
    func `Invalid coordinates read as nil`() {
        #expect(LMKPhotoMetadata.read(from: makeJPEG(gps: (95.0, 0.0, "N", "E"))).coordinate == nil)
    }

    @Test
    func `Reading a file matches reading its bytes`() throws {
        let data = makeJPEG(gps: (10, 20, "N", "E"))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("lmk-metadata-\(UUID().uuidString).jpg")
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(LMKPhotoMetadata.read(from: url) == LMKPhotoMetadata.read(from: data))
    }

    @Test
    func `An item provider without image data reads as empty`() async {
        let provider = NSItemProvider()
        let metadata = await LMKPhotoMetadata.read(from: provider)
        #expect(metadata == .empty)
    }

    @Test
    func `An item provider with image data reads the bytes`() async throws {
        let data = makeJPEG(gps: (48.8566, 2.3522, "N", "E"))
        let provider = NSItemProvider(item: data as NSData, typeIdentifier: UTType.jpeg.identifier)
        let metadata = await LMKPhotoMetadata.read(from: provider)
        #expect(try abs(#require(metadata.coordinate?.latitude) - 48.8566) < 0.001)
    }

    // MARK: - Writing

    @Test
    func `Writing a date and coordinate round-trips through read`() throws {
        let original = makeJPEG(width: 40, height: 30)
        let date = try #require(exifDate("2025:05:06 07:08:09"))
        let coordinate = CLLocationCoordinate2D(latitude: -12.5, longitude: 130.25)
        let stamped = try #require(LMKPhotoMetadata.write(date: date, coordinate: coordinate, to: original))
        let metadata = LMKPhotoMetadata.read(from: stamped)
        #expect(metadata.date == date)
        #expect(try abs(#require(metadata.coordinate?.latitude) - -12.5) < 0.0001)
        #expect(try abs(#require(metadata.coordinate?.longitude) - 130.25) < 0.0001)
        #expect(metadata.pixelSize == CGSize(width: 40, height: 30))
        #expect(stamped.prefix(2) == Data([0xFF, 0xD8]))
    }

    @Test
    func `Writing metadata copies the encoded pixels through untouched`() throws {
        // Noise re-encodes with visible differences at any JPEG quality; a copy has none.
        let original = makeNoisyJPEG()
        let stamped = try #require(LMKPhotoMetadata.write(date: Date(), coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 2), to: original))
        #expect(try decodedPixels(of: stamped) == decodedPixels(of: original))
        #expect(LMKPhotoMetadata.read(from: stamped).coordinate?.latitude == 1)
    }

    @Test
    func `The written date carries its zone and fraction, so it reads back as the same instant anywhere`() throws {
        let date = Date(timeIntervalSince1970: 1_746_515_289.25)
        let stamped = try #require(LMKPhotoMetadata.write(date: date, coordinate: nil, to: makeJPEG()))
        let source = try #require(CGImageSourceCreateWithData(stamped as CFData, nil))
        let properties = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any])
        let exif = try #require(properties[kCGImagePropertyExifDictionary as String] as? [String: Any])
        let offset = try #require(exif[kCGImagePropertyExifOffsetTimeOriginal as String] as? String)
        let seconds = TimeZone.current.secondsFromGMT(for: date)
        #expect(offset == String(format: "%@%02d:%02d", seconds < 0 ? "-" : "+", abs(seconds) / 3600, abs(seconds) % 3600 / 60))
        #expect(exif[kCGImagePropertyExifOffsetTimeDigitized as String] as? String == offset)
        #expect("\(exif[kCGImagePropertyExifSubsecTimeOriginal as String] ?? "")" == "250")
        #expect(LMKPhotoMetadata.read(from: stamped).date == date)
    }

    @Test
    func `A stale offset is replaced by the write, and an offset in the file is honored by the read`() throws {
        let inTokyo = makeJPEG(metadata: [
            kCGImagePropertyExifDictionary as String: [
                kCGImagePropertyExifDateTimeOriginal as String: "2024:03:15 14:30:45",
                kCGImagePropertyExifOffsetTimeOriginal as String: "+09:00",
                kCGImagePropertyExifSubsecTimeOriginal as String: "5",
            ],
        ])
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ssxxx"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let instant = try #require(formatter.date(from: "2024:03:15 14:30:45+09:00")).addingTimeInterval(0.5)
        #expect(LMKPhotoMetadata.read(from: inTokyo).date == instant, "the wall time is read in the zone the file names, not the device's")

        let date = try #require(exifDate("2025:05:06 07:08:09"))
        let restamped = try #require(LMKPhotoMetadata.write(date: date, coordinate: nil, to: inTokyo))
        #expect(LMKPhotoMetadata.read(from: restamped).date == date, "the old +09:00 does not shift the new wall time")
    }

    @Test
    func `Nil fields leave existing metadata alone`() throws {
        let date = try #require(exifDate("2020:02:02 02:02:02"))
        let withDate = try #require(LMKPhotoMetadata.write(date: date, coordinate: nil, to: makeJPEG(gps: (1, 2, "N", "E"))))
        let metadata = LMKPhotoMetadata.read(from: withDate)
        #expect(metadata.date == date)
        #expect(metadata.coordinate?.latitude == 1)
        let rewritten = try #require(LMKPhotoMetadata.write(date: nil, coordinate: CLLocationCoordinate2D(latitude: 3, longitude: 4), to: withDate))
        let updated = LMKPhotoMetadata.read(from: rewritten)
        #expect(updated.date == date)
        #expect(updated.coordinate?.latitude == 3)
        #expect(updated.coordinate?.longitude == 4)
    }

    @Test
    func `An invalid coordinate is not written and non-image bytes fail`() throws {
        let stamped = try #require(LMKPhotoMetadata.write(date: nil, coordinate: CLLocationCoordinate2D(latitude: 200, longitude: 0), to: makeJPEG()))
        #expect(LMKPhotoMetadata.read(from: stamped).coordinate == nil)
        #expect(LMKPhotoMetadata.write(date: Date(), coordinate: nil, to: Data([1, 2, 3])) == nil)
    }

    @Test
    func `A file that is not an image is left as it was`() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("lmk-notimage-\(UUID().uuidString).jpg")
        let bytes = Data([1, 2, 3, 4])
        try bytes.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(throws: CocoaError.self) {
            try LMKPhotoMetadata.write(date: Date(), coordinate: nil, to: url)
        }
        #expect(try Data(contentsOf: url) == bytes)
    }

    @Test
    func `The instance form and the file form write the same fields`() throws {
        let date = try #require(exifDate("2021:03:04 05:06:07"))
        let value = LMKPhotoMetadata(date: date, coordinate: CLLocationCoordinate2D(latitude: 5, longitude: 6))
        let stamped = try #require(value.writing(to: makeJPEG()))
        #expect(LMKPhotoMetadata.read(from: stamped).date == date)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("lmk-write-\(UUID().uuidString).jpg")
        try makeJPEG().write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        try LMKPhotoMetadata.write(date: date, coordinate: value.coordinate, to: url)
        let fromFile = LMKPhotoMetadata.read(from: url)
        #expect(fromFile.date == date)
        #expect(fromFile.coordinate?.latitude == 5)
    }

    @Test
    func `Equality compares every field`() {
        let a = LMKPhotoMetadata(date: Date(timeIntervalSince1970: 1), coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 2), pixelSize: CGSize(width: 3, height: 4), orientation: .left)
        var b = a
        #expect(a == b)
        b.coordinate = CLLocationCoordinate2D(latitude: 1, longitude: 3)
        #expect(a != b)
        #expect(LMKPhotoMetadata() == .empty)
    }
}

// MARK: - Test Helpers

/// A 64 x 64 JPEG of pseudo-random pixels, encoded lossily.
private func makeNoisyJPEG() -> Data {
    let side = 64
    var bytes = [UInt8](repeating: 0, count: side * side * 4)
    var seed: UInt32 = 12345
    for index in bytes.indices {
        seed = seed &* 1_103_515_245 &+ 12345
        bytes[index] = UInt8((seed >> 16) & 0xFF)
    }
    guard let provider = CGDataProvider(data: Data(bytes) as CFData),
          let image = CGImage(
              width: side, height: side, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: side * 4,
              space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
              provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent
          ) else { return Data() }
    let mutableData = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(mutableData, UTType.jpeg.identifier as CFString, 1, nil) else { return Data() }
    CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.7] as CFDictionary)
    CGImageDestinationFinalize(destination)
    return mutableData as Data
}

/// The decoded pixel bytes of an image file.
private func decodedPixels(of data: Data) throws -> [UInt8] {
    let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
    let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
    let pixels = try #require(image.dataProvider?.data) as Data
    return [UInt8](pixels)
}

private func makeJPEG(width: Int = 10, height: Int = 10, metadata: [String: Any] = [:]) -> Data {
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { context in
        UIColor.green.setFill()
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    }
    guard let cgImage = image.cgImage else { return Data() }
    let mutableData = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(mutableData, UTType.jpeg.identifier as CFString, 1, nil) else { return Data() }
    CGImageDestinationAddImage(destination, cgImage, metadata as CFDictionary)
    CGImageDestinationFinalize(destination)
    return mutableData as Data
}

private func makeJPEG(gps: (latitude: Double, longitude: Double, latRef: String, lonRef: String)) -> Data {
    makeJPEG(metadata: [
        kCGImagePropertyGPSDictionary as String: [
            kCGImagePropertyGPSLatitude as String: gps.latitude,
            kCGImagePropertyGPSLongitude as String: gps.longitude,
            kCGImagePropertyGPSLatitudeRef as String: gps.latRef,
            kCGImagePropertyGPSLongitudeRef as String: gps.lonRef,
        ],
    ])
}
