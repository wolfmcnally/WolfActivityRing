//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import SwiftUI

public struct ActivityRingProgressKey: EnvironmentKey {
    public static let defaultValue: Double = 0
}

extension EnvironmentValues {
    public var activityRingProgress: Double {
        get { self[ActivityRingProgressKey.self] }
        set { self[ActivityRingProgressKey.self] = newValue }
    }
}

public struct ActivityRingOptions {
    var radius: Double = 30
    var thickness: Double = 10
    var color: Color = .accentColor
    var tipColor: Color? = nil
    var backgroundColor: Color = .init(.systemGray6)
    var tipShadowColor: Color = .black.opacity(0.3)
    var outlineColor: Color = .init(.systemGray4)
    var outlineThickness: Double = 1
    
    public init() {
    }
}

public struct ActivityRing<Content>: View where Content: View {
    let progress: Double
    let options: ActivityRingOptions
    let content: Content

    public init(
        progress: Double,
        options: ActivityRingOptions,
        @ViewBuilder content: () -> Content)
    {
        self.progress = progress
        self.options = options
        self.content = content()
    }
    
    private var effectiveTipColor: Color {
        options.tipColor ?? options.color
    }
    
    public var body: some View {
        let activityAngularGradient = AngularGradient(
            gradient: Gradient(colors: [options.color, effectiveTipColor]),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360.0 * progress))
        
        ZStack {
            if options.backgroundColor != .clear {
                Circle()
                    .stroke(options.backgroundColor, lineWidth: options.thickness)
                    .frame(width: options.radius * 2.0)
            }
            if options.outlineColor != .clear {
                Circle()
                    .stroke(options.outlineColor, lineWidth: options.outlineThickness)
                    .frame(width:(options.radius * 2.0) + options.thickness - options.outlineThickness)
                Circle()
                    .stroke(options.outlineColor, lineWidth: options.outlineThickness)
                    .frame(width:(options.radius * 2.0) - options.thickness + options.outlineThickness)
            }
            Circle()
                .trim(from: 0, to: self.progress)
                .stroke(
                    activityAngularGradient,
                    style: StrokeStyle(lineWidth: options.thickness, lineCap: .round))
                .rotationEffect(Angle(degrees: -90))
                .frame(width: options.radius * 2.0)
                .animation(.easeOut, value: progress)
            RingCap(progress: progress,
                            ringRadius: options.radius)
                .fill(effectiveTipColor, strokeBorder: effectiveTipColor, lineWidth: 1) // hide seam
                .frame(width:options.thickness, height:options.thickness)
                .shadow(color: options.tipShadowColor,
                        radius: 2.5,
                        x: ringTipShadowOffset.x,
                        y: ringTipShadowOffset.y
                )
                .clipShape(
                    RingClipShape(radius: options.radius, thickness: options.thickness)
                )
                .opacity(tipOpacity)
                .animation(.easeOut, value: progress)
            content
                .environment(\.activityRingProgress, progress)
        }
        .aspectRatio(1, contentMode: .fill)
        .frame(width: size, height: size)
    }
    
    private var size: Double {
        return options.radius * 2 + options.thickness
    }
    
    private var tipOpacity: Double {
        if progress < 0.95 {
            return 0
        } else {
            return 1
        }
    }
    
    private var ringTipShadowOffset: CGPoint {
        let ringTipPosition = tipPosition(progress: progress, radius: options.radius)
        let shadowPosition = tipPosition(progress: progress + 0.0075, radius: options.radius)
        return CGPoint(x: shadowPosition.x - ringTipPosition.x,
                       y: shadowPosition.y - ringTipPosition.y)
    }
    
    private func tipPosition(progress: Double, radius: Double) -> CGPoint {
        let progressAngle = Angle(degrees: (360.0 * progress) - 90.0)
        return CGPoint(
            x: radius * cos(progressAngle.radians),
            y: radius * sin(progressAngle.radians))
    }
}

extension Shape {
    func fill<Fill: ShapeStyle, Stroke: ShapeStyle>(_ fillStyle: Fill, strokeBorder strokeStyle: Stroke, lineWidth: CGFloat = 1) -> some View {
        self
            .stroke(strokeStyle, lineWidth: lineWidth)
            .background(self.fill(fillStyle))
    }
}

extension ActivityRing where Content == EmptyView {
    public init(
        progress: Double,
        options: ActivityRingOptions
    ) {
        self.init(
            progress: progress,
            options: options
        ) {
            EmptyView()
        }
    }
}

struct RingClipShape: Shape {
    let radius: Double
    let thickness: Double
    
    func path(in rect: CGRect) -> Path {
        let outerRadius = radius + thickness / 2
        let innerRadius = radius - thickness / 2
        let center = CGPoint(x: rect.minX + rect.width / 2, y: rect.minY + rect.height / 2)
        var path = Path()
        path.addArc(center: center, radius: outerRadius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: true)
        path.addArc(center: center, radius: innerRadius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        return path
    }
}

struct RingCap: Shape {
    var progress: Double
    let ringRadius: Double
    
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
        
    func path(in rect: CGRect) -> Path {
        guard progress > 0 else {
            return Path()
        }

        var path = Path()
        let progressAngle = Angle(degrees: (360.0 * progress) - 90.0)
        let tipRadius = rect.width / 2
        let center = CGPoint(
            x: ringRadius * cos(progressAngle.radians) + tipRadius,
            y: ringRadius * sin(progressAngle.radians) + tipRadius
        )
        let startAngle = progressAngle + .degrees(180)
        let endAngle = startAngle - .degrees(180)
        path.addArc(center: center, radius: tipRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        path.closeSubpath()
        return path
    }
}

public struct ActivityRingPercent: View {
    @Environment(\.activityRingProgress) var progress: Double
    
    public var body: some View {
        Text("\(Int(progress * 100))%")
    }
}

#if DEBUG

struct ActivityRingTest: View {
    @State var progress: Double = 0.0
    @State var progress1: Double = 0.0
    @State var progress2: Double = 0.0
    @State var progress3: Double = 0.0
    @State var progress4: Double = 0.0
    @State var progress5: Double = 0.0
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    let ringOptions: ActivityRingOptions = {
        var o = ActivityRingOptions()
        o.tipShadowColor = .clear
        return o
    }()
    
    var ring1Options: ActivityRingOptions {
        var o = ActivityRingOptions()
        o.radius = 20
        o.thickness = 5
        if progress1 <= 1 {
            o.color = .brightGreen
            o.tipColor = .brightGreen
        } else {
            o.color = .darkRed
            o.tipColor = .brightRed
        }
        o.backgroundColor = Color.secondary.opacity(0.2)
        o.outlineColor = .clear
        return o
    }
    
    let ring2Options: ActivityRingOptions = {
        var o = ActivityRingOptions()
        o.color = .yellow
        o.tipColor = .blue
        return o
    }()
    
    let ring3Options: ActivityRingOptions = {
        var o = ActivityRingOptions()
        o.radius = 100
        o.thickness = 23
        o.color = .darkRed
        o.tipColor = .brightRed
        o.backgroundColor = Color.brightRed.opacity(0.2)
        o.outlineColor = .clear
        o.tipShadowColor = .clear
        return o
    }()
    
    let ring4Options: ActivityRingOptions = {
        var o = ActivityRingOptions()
        o.radius = 75
        o.thickness = 23
        o.color = .darkGreen
        o.tipColor = .brightGreen
        o.backgroundColor = Color.brightGreen.opacity(0.2)
        o.outlineColor = .clear
        o.tipShadowColor = .clear
        return o
    }()
    
    let ring5Options: ActivityRingOptions = {
        var o = ActivityRingOptions()
        o.radius = 50
        o.thickness = 23
        o.color = .darkBlue
        o.tipColor = .brightBlue
        o.backgroundColor = Color.brightBlue.opacity(0.2)
        o.outlineColor = .clear
        o.tipShadowColor = .clear
        return o
    }()

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            ActivityRing(
                progress: progress,
                options: ringOptions
            )
            .onReceive(timer) { _ in
                increment(&progress, maxProgress: 1)
            }

            ActivityRing(
                progress: progress1,
                options: ring1Options
            )
            .onReceive(timer) { _ in
                increment(&progress1)
            }

            ActivityRing(
                progress: progress2,
                options: ring2Options
            ) {
                ActivityRingPercent()
                    .font(Font.subheadline.bold())
            }
            .onReceive(timer) { _ in
                increment(&progress2)
            }

            ZStack {
                ActivityRing(
                    progress: progress3,
                    options: ring3Options
                )
                .onReceive(timer) { _ in
                    increment(&progress3)
                }

                ActivityRing(
                    progress: progress4,
                    options: ring4Options
                )
                .onReceive(timer) { _ in
                    increment(&progress4)
                }

                ActivityRing(
                    progress: progress5,
                    options: ring5Options
                )
                .onReceive(timer) { _ in
                    increment(&progress5)
                }
            }
            
            Spacer()
        }
    }
    
    private func increment(_ n: inout Double, maxProgress: Double = 2.0) {
        guard Int.random(in: 0..<10) == 0 else {
            return
        }
        
        guard n < maxProgress else {
            n = 0
            return
        }
        let nextN = Double.random(in: 0.20 ..< 0.40)
        n = min(n + nextN, maxProgress)
    }
}

struct ActivityRing_Previews: PreviewProvider {
    static var previews: some View {
        ActivityRingTest()
            .preferredColorScheme(.dark)
    }
}

let darken = 0.7
let brightR: SIMD3<Double> = [1, 0.2, 0.2]
let darkR = brightR * darken
let brightG: SIMD3<Double> = [0, 1, 0]
let darkG = brightG * darken
let brightB: SIMD3<Double> = [0, 0.7, 1]
let darkB = brightB * darken

extension Color {
    static let brightRed = Color(brightR)
    static let darkRed = Color(darkR)
    static let brightGreen = Color(brightG)
    static let darkGreen = Color(darkG)
    static let brightBlue = Color(brightB)
    static let darkBlue = Color(darkB)
}

extension Color {
    init(_ simd: SIMD3<Double>) {
        self.init(red: simd.x, green: simd.y, blue: simd.z)
    }
}

#endif
