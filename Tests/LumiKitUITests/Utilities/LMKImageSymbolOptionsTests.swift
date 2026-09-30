//
//  LMKImageSymbolOptionsTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKImageSymbolOptionsTests {
    @Test
    func `Symbol options render sizes, weights, and every rendering mode`() throws {
        let plain = try #require(LMKImage.symbol("heart.fill", options: LMKImage.SymbolOptions(pointSize: 24, weight: .bold, scale: .large)))
        #expect(plain.renderingMode != .alwaysOriginal, "template by default")
        #expect(plain.size.width > 0)

        let mono = try #require(LMKImage.symbol("heart.fill", options: LMKImage.SymbolOptions(pointSize: 12, rendering: .monochrome(.red))))
        #expect(mono.renderingMode == .alwaysOriginal)
        #expect(mono.size.width < plain.size.width, "point size drives the raster size")

        #expect(LMKImage.symbol("heart.fill", options: LMKImage.SymbolOptions(rendering: .hierarchical(.blue))) != nil)
        #expect(LMKImage.symbol("person.2.fill", options: LMKImage.SymbolOptions(rendering: .palette([.red, .blue]))) != nil)
        #expect(LMKImage.symbol("cloud.sun.fill", options: LMKImage.SymbolOptions(rendering: .multicolor)) != nil)
        #expect(LMKImage.symbol("no.such.symbol.xyz", options: LMKImage.SymbolOptions()) == nil)
    }

    @Test
    func `Variable values clamp to 0...1 and the iOS 26 modes still produce an image`() {
        let options = LMKImage.SymbolOptions(pointSize: 20, variableValue: 1.7, variableValueMode: .draw, colorRenderingMode: .gradient)
        #expect(options.variableValue == 1)
        #expect(LMKImage.SymbolOptions(variableValue: -2).variableValue == 0)
        #expect(LMKImage.symbol("wifi", options: options) != nil)
        #expect(LMKImage.symbol("speaker.wave.3.fill", options: LMKImage.SymbolOptions(variableValue: 0.4, variableValueMode: .color)) != nil)
        #expect(LMKImage.SymbolOptions.VariableValueMode.allCases.count == 3)
        #expect(LMKImage.SymbolOptions.ColorRenderingMode.allCases.count == 3)
    }

    @Test
    func `The point-size convenience routes through the options`() {
        #expect(LMKImage.symbol("star.fill", pointSize: 20, color: .red)?.renderingMode == .alwaysOriginal)
        #expect(LMKImage.symbol("star.fill", pointSize: 20)?.renderingMode != .alwaysOriginal)
    }

    @Test
    func `HDR downsampling goes through UIImageReader and honors the size and scale`() throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let data = try #require(UIGraphicsImageRenderer(size: CGSize(width: 120, height: 60), format: format).image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 120, height: 60))
        }.pngData())

        let image = try #require(LMKImage.downsample(data: data, maxPixelSize: 40, options: LMKImage.DownsampleOptions(prefersHighDynamicRange: true)))
        #expect(max(image.size.width, image.size.height) * image.scale <= 40)
        #expect(image.size.width > image.size.height, "aspect ratio kept")

        let scaled = try #require(LMKImage.downsample(data: data, maxPixelSize: 40, options: LMKImage.DownsampleOptions(scale: 2, prefersHighDynamicRange: true)))
        #expect(scaled.scale == 2)
        #expect(scaled.size.width * 2 == image.size.width * image.scale, "same pixels, reported in points at 2×")

        #expect(LMKImage.downsample(data: data, maxPixelSize: 0, options: LMKImage.DownsampleOptions(prefersHighDynamicRange: true)) == nil)
        #expect(LMKImage.downsample(data: Data([0, 1, 2]), maxPixelSize: 40, options: LMKImage.DownsampleOptions(prefersHighDynamicRange: true)) == nil)
    }
}
