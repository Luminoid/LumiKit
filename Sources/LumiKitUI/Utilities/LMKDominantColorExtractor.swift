import CoreGraphics
import UIKit

/// Extracts dominant color(s) from an image.
///
/// Approach: downsample to a small grid, bin pixels into a 3D RGB histogram
/// (6×6×6 = 216 buckets), then pick the bucket(s) you want.
///
/// The default `.modal` strategy returns the densest bucket — the single color
/// range the subject's pixels cluster into. It preserves true subject identity
/// regardless of saturation: a black cat resolves to black, a British Blue to
/// cool grey, an orange tabby to orange. The `.average` strategy returns the
/// arithmetic mean of every sampled pixel — useful for the overall "vibe" of
/// gradients or photos with no clear subject, but mixes subject + background
/// into a muddy result for most subject photos.
///
/// `dominantColors(...)` returns a palette of the top-N densest buckets in
/// frequency order — use it when you want a color set (e.g. a featured swatch
/// row) rather than a single accent.
///
/// For best subject accuracy, pass a subject-lifted image
/// (`VNGenerateForegroundInstanceMaskRequest` or similar) with
/// `ignoringTransparent: true`, so only the subject's pixels contribute.
public nonisolated enum LMKDominantColorExtractor {
    /// Strategy for collapsing pixel samples into a single dominant color.
    public enum Strategy: Sendable {
        /// Densest histogram bucket — the modal color. Best for subject identity:
        /// preserves low-saturation coats (black, white, grey-blue) and ignores
        /// outlier pixels.
        case modal
        /// Arithmetic mean of every sampled pixel. Useful for the overall "vibe"
        /// of a gradient or flat illustration; tends to muddy subject photos.
        case average
        /// Most saturated histogram bucket, with a population tie-breaker. Picks
        /// the "accent color" — a small red flower against grey rocks resolves
        /// to red, not grey. Buckets covering < 0.5% of samples are dropped to
        /// avoid single-pixel noise. Falls through to modal for grayscale
        /// images (every bucket has saturation 0).
        case vibrant
    }

    /// Extract a single dominant color from an image.
    ///
    /// - Parameters:
    ///   - image: Source image. For best subject accuracy, pass a subject-lifted
    ///     (transparent background) version when available.
    ///   - ignoringTransparent: When true, pixels with alpha < ~0.9 are excluded
    ///     so only the lifted subject contributes. Returns nil if every sampled
    ///     pixel is transparent.
    ///   - strategy: How to collapse samples into a color (default `.modal`).
    /// - Returns: The dominant color, or nil if the image cannot be processed
    ///   (or all samples were skipped when ignoring transparency).
    public static func dominantColor(
        from image: UIImage,
        ignoringTransparent: Bool = false,
        strategy: Strategy = .modal
    ) -> UIColor? {
        guard let samples = samplePixels(from: image, ignoringTransparent: ignoringTransparent) else {
            return nil
        }
        switch strategy {
        case .modal: return modalColor(from: samples)
        case .average: return averageColor(samples)
        case .vibrant: return vibrantColor(from: samples)
        }
    }

    /// Extract a palette of dominant colors, ordered by frequency.
    ///
    /// Returns up to `count` non-empty histogram buckets. Each color is the
    /// weighted average of pixels that fell into its bucket. May return fewer
    /// than `count` colors if the image has fewer non-empty buckets (e.g. a
    /// solid-color image returns one).
    ///
    /// - Parameters:
    ///   - image: Source image.
    ///   - count: Maximum palette size. Must be ≥ 1.
    ///   - ignoringTransparent: When true, pixels with alpha < ~0.9 are excluded.
    /// - Returns: Up to `count` colors in descending frequency order, or `[]`
    ///   if the image cannot be processed.
    public static func dominantColors(
        from image: UIImage,
        count: Int,
        ignoringTransparent: Bool = false
    ) -> [UIColor] {
        guard count >= 1 else { return [] }
        guard let samples = samplePixels(from: image, ignoringTransparent: ignoringTransparent) else {
            return []
        }
        return topBucketColors(from: samples, count: count)
    }

    // MARK: - Pixel Sampling

    /// Downsample to 40×40 and collect RGB triples, optionally filtering by alpha.
    private static func samplePixels(
        from image: UIImage,
        ignoringTransparent: Bool
    ) -> [(r: UInt8, g: UInt8, b: UInt8)]? {
        guard let cgImage = image.cgImage else { return nil }

        let size = 40
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * size
        var pixelData = [UInt8](repeating: 0, count: size * size * bytesPerPixel)

        // Pre-multiplied RGBA is the only RGBA format `CGBitmapContextCreate`
        // supports on iOS. Pre-multiplication only affects partially-
        // transparent pixels — fully opaque pixels (alpha = 255) keep their
        // RGB unchanged, and we drop the rest via the alpha threshold below.
        guard let context = CGContext(
            data: &pixelData,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.clear(CGRect(x: 0, y: 0, width: size, height: size))
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size, height: size))

        // When sampling a lifted image, require near-opaque alpha so residual
        // edge pixels (semi-transparent fur blended with the transparent
        // background) don't pollute the histogram toward neutral grey. When
        // sampling a raw photo, drop the outer border ring so typical
        // backgrounds contribute less than the centered subject.
        var samples: [(r: UInt8, g: UInt8, b: UInt8)] = []
        samples.reserveCapacity(size * size)

        let alphaThreshold: UInt8 = 230
        let centerMargin = ignoringTransparent ? 0 : size / 5 // drop ~20% border ring

        for y in centerMargin ..< (size - centerMargin) {
            for x in centerMargin ..< (size - centerMargin) {
                let i = (y * size + x) * bytesPerPixel
                let alpha = pixelData[i + 3]
                if ignoringTransparent, alpha < alphaThreshold { continue }
                samples.append((pixelData[i], pixelData[i + 1], pixelData[i + 2]))
            }
        }

        guard !samples.isEmpty else { return nil }
        return samples
    }

    // MARK: - Histogram

    /// Coarse-bin each sample into a 6×6×6 RGB cube and return per-bucket
    /// (count, sumR, sumG, sumB) accumulators. Bucket count chosen so
    /// neighbouring tones (e.g., light and medium grey) aggregate rather than
    /// splitting across adjacent bins.
    private static func histogram(_ samples: [(r: UInt8, g: UInt8, b: UInt8)]) -> (
        counts: [Int],
        sumR: [Int],
        sumG: [Int],
        sumB: [Int]
    ) {
        let dimension = 6
        let bucketSize = 256 / dimension
        var counts = [Int](repeating: 0, count: dimension * dimension * dimension)
        var sumR = [Int](repeating: 0, count: counts.count)
        var sumG = [Int](repeating: 0, count: counts.count)
        var sumB = [Int](repeating: 0, count: counts.count)

        for sample in samples {
            let rIdx = min(Int(sample.r) / bucketSize, dimension - 1)
            let gIdx = min(Int(sample.g) / bucketSize, dimension - 1)
            let bIdx = min(Int(sample.b) / bucketSize, dimension - 1)
            let index = (rIdx * dimension + gIdx) * dimension + bIdx
            counts[index] += 1
            sumR[index] += Int(sample.r)
            sumG[index] += Int(sample.g)
            sumB[index] += Int(sample.b)
        }

        return (counts, sumR, sumG, sumB)
    }

    private static func modalColor(from samples: [(r: UInt8, g: UInt8, b: UInt8)]) -> UIColor {
        let h = histogram(samples)
        guard let bestIndex = h.counts.indices.max(by: { h.counts[$0] < h.counts[$1] }),
              h.counts[bestIndex] > 0
        else {
            return averageColor(samples)
        }
        return bucketColor(index: bestIndex, histogram: h)
    }

    /// Score each non-trivial bucket on saturation (primary) with a population
    /// tie-breaker, then return the winning bucket's average color. Grayscale
    /// images (every bucket sat=0) fall through to the most-populated bucket,
    /// which is effectively `.modal`.
    private static func vibrantColor(from samples: [(r: UInt8, g: UInt8, b: UInt8)]) -> UIColor {
        let h = histogram(samples)
        let nonEmpty = h.counts.indices.filter { h.counts[$0] > 0 }
        guard !nonEmpty.isEmpty else { return averageColor(samples) }

        // Drop buckets too rare to be meaningful (< 0.5% of samples or < 2 px)
        // so a single bright outlier can't dominate.
        let minCount = max(2, samples.count / 200)
        let candidates = nonEmpty.filter { h.counts[$0] >= minCount }
        let pool = candidates.isEmpty ? nonEmpty : candidates

        let maxCount = CGFloat(pool.map { h.counts[$0] }.max() ?? 1)

        var bestIndex = pool[0]
        var bestScore: CGFloat = -1
        for idx in pool {
            let color = bucketColor(index: idx, histogram: h)
            var hue: CGFloat = 0
            var sat: CGFloat = 0
            var brightness: CGFloat = 0
            var alpha: CGFloat = 0
            color.getHue(&hue, saturation: &sat, brightness: &brightness, alpha: &alpha)
            let populationFactor = CGFloat(h.counts[idx]) / maxCount
            // Saturation is primary; population breaks ties between equally
            // saturated buckets. Coefficients chosen so saturation differences
            // outweigh moderate population differences.
            let score = sat * 2.0 + populationFactor * 0.5
            if score > bestScore {
                bestScore = score
                bestIndex = idx
            }
        }
        return bucketColor(index: bestIndex, histogram: h)
    }

    private static func topBucketColors(
        from samples: [(r: UInt8, g: UInt8, b: UInt8)],
        count: Int
    ) -> [UIColor] {
        let h = histogram(samples)
        let nonEmpty = h.counts.indices.filter { h.counts[$0] > 0 }
        let sorted = nonEmpty.sorted { h.counts[$0] > h.counts[$1] }
        return sorted.prefix(count).map { bucketColor(index: $0, histogram: h) }
    }

    private static func bucketColor(
        index: Int,
        histogram h: (counts: [Int], sumR: [Int], sumG: [Int], sumB: [Int])
    ) -> UIColor {
        let count = h.counts[index]
        return UIColor(
            red: CGFloat(h.sumR[index]) / CGFloat(count) / 255.0,
            green: CGFloat(h.sumG[index]) / CGFloat(count) / 255.0,
            blue: CGFloat(h.sumB[index]) / CGFloat(count) / 255.0,
            alpha: 1.0
        )
    }

    private static func averageColor(_ samples: [(r: UInt8, g: UInt8, b: UInt8)]) -> UIColor {
        var totalR = 0
        var totalG = 0
        var totalB = 0
        for sample in samples {
            totalR += Int(sample.r)
            totalG += Int(sample.g)
            totalB += Int(sample.b)
        }
        let count = CGFloat(samples.count)
        return UIColor(
            red: CGFloat(totalR) / count / 255.0,
            green: CGFloat(totalG) / count / 255.0,
            blue: CGFloat(totalB) / count / 255.0,
            alpha: 1.0
        )
    }
}
