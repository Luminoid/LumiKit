//
//  LMKImage.swift
//  LumiKit
//
//  Image utility helpers.
//

import UIKit
import UniformTypeIdentifiers

/// Image utility helpers.
public nonisolated enum LMKImage {
    /// Create an SF Symbol image with a given point size and optional color.
    public static func symbol(_ name: String, pointSize: CGFloat, color: UIColor? = nil) -> UIImage? {
        symbol(name, options: SymbolOptions(pointSize: pointSize, rendering: color.map { SymbolOptions.Rendering.monochrome($0) } ?? .template))
    }

    // MARK: - Symbol Options

    /// How an SF Symbol renders: size, weight, scale, rendering mode, and the iOS 26 variable-value
    /// and color-rendering modes (ignored before 26, where the plain configuration applies).
    public struct SymbolOptions: Sendable, Equatable {
        /// Color rendering of the symbol's layers.
        public enum Rendering: Sendable, Equatable {
            /// Template image; tinted by the view's `tintColor`.
            case template
            /// Baked into the image (`alwaysOriginal`).
            case monochrome(UIColor)
            /// Hierarchical: one color at descending opacities per layer.
            case hierarchical(UIColor)
            /// Palette: one color per layer, in layer order.
            case palette([UIColor])
            /// The symbol's own multicolor layers.
            case multicolor
        }

        /// How variable-value layers render (iOS 26 `UIImage.SymbolVariableValueMode`).
        public enum VariableValueMode: Sendable, Hashable, CaseIterable {
            case automatic
            /// Each variable layer is either on or off against its threshold.
            case color
            /// Each variable layer is drawn to its range's length.
            case draw
        }

        /// How color layers render (iOS 26 `UIImage.SymbolColorRenderingMode`).
        public enum ColorRenderingMode: Sendable, Hashable, CaseIterable {
            case automatic
            case flat
            case gradient
        }

        /// `nil` = the symbol's natural size.
        public var pointSize: CGFloat?
        public var weight: UIImage.SymbolWeight?
        public var scale: UIImage.SymbolScale?
        public var rendering: Rendering
        /// 0...1 for symbols with variable layers (`wifi`, `speaker.wave.3`); `nil` = not variable.
        public var variableValue: Double?
        /// iOS 26 only; `.automatic` elsewhere.
        public var variableValueMode: VariableValueMode
        /// iOS 26 only; `.automatic` elsewhere.
        public var colorRenderingMode: ColorRenderingMode

        public init(
            pointSize: CGFloat? = nil,
            weight: UIImage.SymbolWeight? = nil,
            scale: UIImage.SymbolScale? = nil,
            rendering: Rendering = .template,
            variableValue: Double? = nil,
            variableValueMode: VariableValueMode = .automatic,
            colorRenderingMode: ColorRenderingMode = .automatic
        ) {
            self.pointSize = pointSize
            self.weight = weight
            self.scale = scale
            self.rendering = rendering
            self.variableValue = variableValue.map { min(1, max(0, $0)) }
            self.variableValueMode = variableValueMode
            self.colorRenderingMode = colorRenderingMode
        }

        /// The `UIImage.SymbolConfiguration` for these options (the 26-only modes are dropped before 26).
        public var configuration: UIImage.SymbolConfiguration {
            var configuration = UIImage.SymbolConfiguration.unspecified
            if let pointSize {
                configuration = configuration.applying(UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight ?? .regular, scale: scale ?? .default))
            } else {
                if let weight { configuration = configuration.applying(UIImage.SymbolConfiguration(weight: weight)) }
                if let scale { configuration = configuration.applying(UIImage.SymbolConfiguration(scale: scale)) }
            }
            switch rendering {
            case .template, .monochrome:
                break
            case let .hierarchical(color):
                configuration = configuration.applying(UIImage.SymbolConfiguration(hierarchicalColor: color))
            case let .palette(colors):
                configuration = configuration.applying(UIImage.SymbolConfiguration(paletteColors: colors))
            case .multicolor:
                configuration = configuration.applying(UIImage.SymbolConfiguration.preferringMulticolor())
            }
            if #available(iOS 26, *) {
                switch variableValueMode {
                case .automatic: break
                case .color: configuration = configuration.applying(UIImage.SymbolConfiguration(variableValueMode: .color))
                case .draw: configuration = configuration.applying(UIImage.SymbolConfiguration(variableValueMode: .draw))
                }
                switch colorRenderingMode {
                case .automatic: break
                case .flat: configuration = configuration.applying(UIImage.SymbolConfiguration(colorRenderingMode: .flat))
                case .gradient: configuration = configuration.applying(UIImage.SymbolConfiguration(colorRenderingMode: .gradient))
                }
            }
            return configuration
        }
    }

    /// An SF Symbol rendered with `options`; `nil` for an unknown name.
    public static func symbol(_ name: String, options: SymbolOptions) -> UIImage? {
        let image: UIImage? = if let value = options.variableValue {
            UIImage(systemName: name, variableValue: value, configuration: options.configuration)
        } else {
            UIImage(systemName: name, withConfiguration: options.configuration)
        }
        guard let image else { return nil }
        if case let .monochrome(color) = options.rendering {
            return image.withTintColor(color, renderingMode: .alwaysOriginal)
        }
        return image
    }

    // MARK: - Composite Image

    /// Create a composite image with an optional background fill and a centered SF Symbol.
    /// - Parameters:
    ///   - name: SF Symbol name.
    ///   - size: Output image canvas size in points.
    ///   - symbolPointSize: Point size for the SF Symbol.
    ///   - tintColor: Color applied to the symbol.
    ///   - backgroundColor: Optional fill color for the background. Defaults to `nil` (transparent).
    /// - Returns: Rendered `UIImage`, or `nil` if the symbol name is invalid.
    @MainActor
    public static func makeSymbolImage(
        _ name: String,
        size: CGSize,
        symbolPointSize: CGFloat,
        tintColor: UIColor,
        backgroundColor: UIColor? = nil
    ) -> UIImage? {
        guard let symbolImage = UIImage(
            systemName: name,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: symbolPointSize)
        )?.withTintColor(tintColor, renderingMode: .alwaysOriginal) else {
            return nil
        }

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            if let backgroundColor {
                backgroundColor.setFill()
                UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
            }
            let symbolSize = symbolImage.size
            let origin = CGPoint(
                x: (size.width - symbolSize.width) / 2,
                y: (size.height - symbolSize.height) / 2
            )
            symbolImage.draw(at: origin)
        }
    }

    // MARK: - JPEG Encoding

    /// Downsample and encode an image as an opaque JPEG.
    ///
    /// Redraws into an opaque RGBX `CGContext` (`.noneSkipLast`) so the encode stays
    /// 3-channel. Required because images produced by
    /// `CGImageSourceCreateThumbnailAtIndex` (and many picker paths) carry
    /// `AlphaPremulLast` even for opaque sources; piping that directly into
    /// `UIImage.jpegData` makes ImageIO log "trying to save an opaque image with
    /// 'AlphaPremulLast' ... will double the required memory when decoding the image".
    /// Drawing via UIKit normalizes EXIF orientation in the same pass.
    /// `nonisolated` so encodes can run on background queues without MainActor hops.
    ///
    /// - Parameters:
    ///   - image: The image to encode.
    ///   - maxPixelSize: Longest edge of the output in pixels (the image's point size times its
    ///     `scale`); larger images are downsampled, never upscaled.
    ///   - quality: JPEG compression quality (0.0--1.0). Default 0.8.
    /// - Returns: Opaque JPEG data, or `nil` if the image is empty or the encode fails.
    public static func encodeJPEG(_ image: UIImage, maxPixelSize: CGFloat, quality: CGFloat = 0.8) -> Data? {
        let size = pixelSize(image.size, scale: image.scale)
        guard size.width > 0, size.height > 0, maxPixelSize > 0 else { return nil }
        let scale = min(1, maxPixelSize / max(size.width, size.height))
        let pixelWidth = Int((size.width * scale).rounded())
        let pixelHeight = Int((size.height * scale).rounded())
        guard pixelWidth > 0, pixelHeight > 0 else { return nil }

        guard let context = CGContext(
            data: nil,
            width: pixelWidth,
            height: pixelHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { return nil }

        // Draw through UIKit so the image's EXIF orientation is applied. Flip the
        // context first: CoreGraphics origins are bottom-left, UIKit's top-left.
        UIGraphicsPushContext(context)
        context.translateBy(x: 0, y: CGFloat(pixelHeight))
        context.scaleBy(x: 1, y: -1)
        image.draw(in: CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))
        UIGraphicsPopContext()
        guard let opaqueImage = context.makeImage() else { return nil }

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else { return nil }
        let options: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: quality]
        CGImageDestinationAddImage(destination, opaqueImage, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }

    // MARK: - Downsampling

    /// Options for `downsample(data:maxPixelSize:options:)`.
    public struct DownsampleOptions: Sendable, Equatable {
        /// Bake the EXIF orientation into the pixels (`kCGImageSourceCreateThumbnailWithTransform`). Default `true`.
        public var appliesOrientation: Bool
        /// Decode from the full image rather than an embedded thumbnail, which may be tiny
        /// (`kCGImageSourceCreateThumbnailFromImageAlways`). Default `true`.
        public var alwaysFromImage: Bool
        /// Decode on the calling thread instead of lazily at first draw. Default `true`.
        public var cachesImmediately: Bool
        /// The `UIImage` scale of the result; pass the display scale when `maxPixelSize` came
        /// from `pixelSize(points:scale:)` so the image reports its size in points. Default `1`.
        public var scale: CGFloat
        /// Keep the source's high dynamic range (gain map or ISO HDR) so an `LMKPhotoBrowserViewController`
        /// with `prefersHDR` shows it: decodes through `UIImageReader` instead of ImageIO
        /// thumbnailing. The EXIF orientation then rides on `imageOrientation` rather than being
        /// baked into the pixels, and `alwaysFromImage` does not apply. Default `false`.
        public var prefersHighDynamicRange: Bool

        public init(appliesOrientation: Bool = true, alwaysFromImage: Bool = true, cachesImmediately: Bool = true, scale: CGFloat = 1, prefersHighDynamicRange: Bool = false) {
            self.appliesOrientation = appliesOrientation
            self.alwaysFromImage = alwaysFromImage
            self.cachesImmediately = cachesImmediately
            self.scale = max(1, scale)
            self.prefersHighDynamicRange = prefersHighDynamicRange
        }
    }

    /// Decodes `data` straight to an image no larger than `maxPixelSize` on its longest edge
    /// (ImageIO thumbnailing), never a full-resolution decode. Smaller images are not upscaled.
    ///
    /// - Returns: `nil` when the bytes are not an image or `maxPixelSize` is not positive.
    public static func downsample(data: Data, maxPixelSize: CGFloat, options: DownsampleOptions = DownsampleOptions()) -> UIImage? {
        if options.prefersHighDynamicRange {
            return downsampleHDR(maxPixelSize: maxPixelSize, options: options) { $0.image(data: data) }
        }
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }
        return downsample(source: source, maxPixelSize: maxPixelSize, options: options)
    }

    /// `downsample(data:maxPixelSize:options:)` from a file, without reading the whole file into memory first.
    public static func downsample(fileURL: URL, maxPixelSize: CGFloat, options: DownsampleOptions = DownsampleOptions()) -> UIImage? {
        if options.prefersHighDynamicRange {
            return downsampleHDR(maxPixelSize: maxPixelSize, options: options) { $0.image(contentsOf: fileURL) }
        }
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, sourceOptions) else { return nil }
        return downsample(source: source, maxPixelSize: maxPixelSize, options: options)
    }

    /// `downsample(data:maxPixelSize:options:)` on the global executor; only the result crosses back.
    @concurrent
    public static func downsample(data: Data, maxPixelSize: CGFloat, options: DownsampleOptions = DownsampleOptions()) async -> UIImage? {
        if options.prefersHighDynamicRange {
            return downsampleHDR(maxPixelSize: maxPixelSize, options: options) { $0.image(data: data) }
        }
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }
        return downsample(source: source, maxPixelSize: maxPixelSize, options: options)
    }

    /// `downsample(fileURL:maxPixelSize:options:)` on the global executor.
    @concurrent
    public static func downsample(fileURL: URL, maxPixelSize: CGFloat, options: DownsampleOptions = DownsampleOptions()) async -> UIImage? {
        if options.prefersHighDynamicRange {
            return downsampleHDR(maxPixelSize: maxPixelSize, options: options) { $0.image(contentsOf: fileURL) }
        }
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, sourceOptions) else { return nil }
        return downsample(source: source, maxPixelSize: maxPixelSize, options: options)
    }

    /// The `UIImageReader` path: HDR preserved, thumbnail no larger than `maxPixelSize` per side.
    private static func downsampleHDR(maxPixelSize: CGFloat, options: DownsampleOptions, read: (UIImageReader) -> UIImage?) -> UIImage? {
        guard maxPixelSize > 0 else { return nil }
        var configuration = UIImageReader.Configuration()
        configuration.prefersHighDynamicRange = true
        configuration.preparesImagesForDisplay = options.cachesImmediately
        configuration.preferredThumbnailSize = CGSize(width: maxPixelSize, height: maxPixelSize)
        guard let image = read(UIImageReader(configuration: configuration)) else { return nil }
        guard options.scale != image.scale, let cgImage = image.cgImage else { return image }
        return UIImage(cgImage: cgImage, scale: options.scale, orientation: image.imageOrientation)
    }

    /// The pixel count for `points` at `scale`, rounded up (the `maxPixelSize` for a point-sized target).
    public static func pixelSize(points: CGFloat, scale: CGFloat) -> CGFloat {
        ceil(points * max(1, scale))
    }

    /// `size` in pixels at `scale`, each side rounded up.
    public static func pixelSize(_ size: CGSize, scale: CGFloat) -> CGSize {
        CGSize(width: pixelSize(points: size.width, scale: scale), height: pixelSize(points: size.height, scale: scale))
    }

    /// Downsamples `data` to `maxPixelSize` and encodes it as an opaque JPEG (`encodeJPEG`), the
    /// one-call import path for picked photos: never a full-resolution decode, orientation baked in.
    public static func downsampledJPEG(data: Data, maxPixelSize: CGFloat, quality: CGFloat = 0.8) -> Data? {
        guard let image = downsample(data: data, maxPixelSize: maxPixelSize) else { return nil }
        return encodeJPEG(image, maxPixelSize: maxPixelSize, quality: quality)
    }

    /// The pixel size of the image in `data` with its EXIF orientation applied, read from the
    /// header without decoding. `nil` when the bytes are not an image.
    public static func imageSize(of data: Data) -> CGSize? {
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }
        return imageSize(of: source)
    }

    /// `imageSize(of:)` for a file.
    public static func imageSize(of fileURL: URL) -> CGSize? {
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, sourceOptions) else { return nil }
        return imageSize(of: source)
    }

    private static var sourceOptions: CFDictionary { [kCGImageSourceShouldCache: false] as CFDictionary }

    private static func downsample(source: CGImageSource, maxPixelSize: CGFloat, options: DownsampleOptions) -> UIImage? {
        guard maxPixelSize > 0, CGImageSourceGetCount(source) > 0 else { return nil }
        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: options.alwaysFromImage,
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            // Capped so "no limit" (`.infinity`, `.greatestFiniteMagnitude`) converts instead of trapping.
            kCGImageSourceThumbnailMaxPixelSize: Int(min(maxPixelSize.rounded(.up), CGFloat(Int32.max))),
            kCGImageSourceCreateThumbnailWithTransform: options.appliesOrientation,
            kCGImageSourceShouldCacheImmediately: options.cachesImmediately,
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary) else { return nil }
        return UIImage(cgImage: cgImage, scale: options.scale, orientation: .up)
    }

    private static func imageSize(of source: CGImageSource) -> CGSize? {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
              let height = properties[kCGImagePropertyPixelHeight] as? CGFloat else {
            return nil
        }
        let orientation = (properties[kCGImagePropertyOrientation] as? UInt32).flatMap(CGImagePropertyOrientation.init(rawValue:)) ?? .up
        switch orientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            return CGSize(width: height, height: width)
        default:
            return CGSize(width: width, height: height)
        }
    }

    // MARK: - Pixel Buffer

    /// One Core Image context for the module's renders (the QR generator shares it).
    static let ciContext = CIContext()

    /// Convert a `CVPixelBuffer` to JPEG `Data`.
    /// - Parameters:
    ///   - pixelBuffer: The pixel buffer to convert.
    ///   - attachments: Optional metadata attachments.
    ///   - compressionQuality: JPEG compression quality (0.0--1.0). Default 0.9.
    public static func jpegData(withPixelBuffer pixelBuffer: CVPixelBuffer, attachments: CFDictionary?, compressionQuality: CGFloat = 0.9) -> Data? {
        let renderedCIImage = CIImage(cvImageBuffer: pixelBuffer)
        guard let renderedCGImage = ciContext.createCGImage(renderedCIImage, from: renderedCIImage.extent) else {
            return nil
        }
        guard let data = CFDataCreateMutable(kCFAllocatorDefault, 0) else {
            return nil
        }
        guard let cgImageDestination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
            return nil
        }
        var imageProperties: [String: Any] = (attachments as? [String: Any]) ?? [:]
        imageProperties[kCGImageDestinationLossyCompressionQuality as String] = compressionQuality
        CGImageDestinationAddImage(cgImageDestination, renderedCGImage, imageProperties as CFDictionary)
        if CGImageDestinationFinalize(cgImageDestination) {
            return data as Data
        }
        return nil
    }
}
