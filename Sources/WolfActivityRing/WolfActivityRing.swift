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

public struct ActivityRing<Content>: View where Content: View {
    let progress: Double
    let radius: Double
    let thickness: Double
    let color: Color
    let tipColor: Color?
    let backgroundColor: Color?
    let tipShadowColor: Color?
    let outlineColor: Color?
    let outlineThickness: Double?
    let content: Content

    public init(
        progress: Double,
        radius: Double = 30,
        thickness: Double = 10,
        color: Color = .accentColor,
        tipColor: Color? = nil,
        backgroundColor: Color? = Color(.systemGray6),
        tipShadowColor: Color? = Color.black.opacity(0.3),
        outlineColor: Color? = Color(.systemGray4),
        outlineThickness: Double? = 1,
        @ViewBuilder content: () -> Content)
    {
        self.progress = progress
        self.radius = radius
        self.thickness = thickness
        self.color = color
        self.tipColor = tipColor
        self.backgroundColor = backgroundColor
        self.tipShadowColor = tipShadowColor
        self.outlineColor = outlineColor
        self.outlineThickness = outlineThickness
        self.content = content()
    }
    
    public var body: some View {
        let activityAngularGradient = AngularGradient(
            gradient: Gradient(colors: [color, effectiveTipColor]),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360.0 * progress))
        
        ZStack {
            if let backgroundColor = backgroundColor {
                Circle()
                    .stroke(backgroundColor, lineWidth: thickness)
                    .frame(width: radius * 2.0)
            }
            if let outlineColor = outlineColor {
                Circle()
                    .stroke(outlineColor, lineWidth: effectiveOutlineThickness)
                    .frame(width:(radius * 2.0) + thickness - effectiveOutlineThickness)
                Circle()
                    .stroke(outlineColor, lineWidth: effectiveOutlineThickness)
                    .frame(width:(radius * 2.0) - thickness + effectiveOutlineThickness)
            }
            Circle()
                .trim(from: 0, to: self.progress)
                .stroke(
                    activityAngularGradient,
                    style: StrokeStyle(lineWidth: thickness, lineCap: .round))
                .rotationEffect(Angle(degrees: -90))
                .frame(width: radius * 2.0)
                .animation(.easeOut, value: progress)
            ActivityRingTip(progress: progress,
                            ringRadius: radius)
                .fill(effectiveTipColor)
                .frame(width:thickness, height:thickness)
                .shadow(color: effectiveTipShadowColor,
                        radius: 2.5,
                        x: ringTipShadowOffset.x,
                        y: ringTipShadowOffset.y
                )
                .clipShape(
                    RingShape(radius: radius, thickness: thickness)
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
        return radius * 2 + thickness
    }
    
    private var effectiveTipColor: Color {
        tipColor ?? color
    }
    
    private var effectiveOutlineThickness: Double {
        outlineThickness ?? 1
    }
    
    private var tipOpacity: Double {
        if progress < 0.95 {
            return 0
        } else {
            return 1
        }
    }
    
    private var effectiveTipShadowColor: Color {
        tipShadowColor ?? Color.black.opacity(0.3)
    }
    
    private var ringTipShadowOffset: CGPoint {
        let ringTipPosition = tipPosition(progress: progress, radius: radius)
        let shadowPosition = tipPosition(progress: progress + 0.0075, radius: radius)
        return CGPoint(x: shadowPosition.x - ringTipPosition.x,
                       y: shadowPosition.y - ringTipPosition.y)
    }
    
    private func tipPosition(progress:Double, radius:Double) -> CGPoint {
        let progressAngle = Angle(degrees: (360.0 * progress) - 90.0)
        return CGPoint(
            x: radius * cos(progressAngle.radians),
            y: radius * sin(progressAngle.radians))
    }
}

extension ActivityRing where Content == EmptyView {
    public init(
        progress: Double,
        radius: Double = 30,
        thickness: Double = 10,
        color: Color = .accentColor,
        tipColor: Color? = nil,
        backgroundColor: Color? = Color(.systemGray6),
        tipShadowColor: Color? = Color.black.opacity(0.3),
        outlineColor: Color? = Color(.systemGray4),
        outlineThickness: Double? = 1
    ) {
        self.init(
            progress: progress,
            radius: radius,
            thickness: thickness,
            color: color,
            tipColor: tipColor,
            backgroundColor: backgroundColor,
            tipShadowColor: tipShadowColor,
            outlineColor: outlineColor,
            outlineThickness: outlineThickness
        ) {
            EmptyView()
        }
    }
}

struct RingShape: Shape {
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

struct ActivityRingTip: Shape {
    var progress: Double
    let ringRadius: Double
    
    private var position: CGPoint {
        let progressAngle = Angle(degrees: (360.0 * progress) - 90.0)
        return CGPoint(
            x: ringRadius * cos(progressAngle.radians),
            y: ringRadius * sin(progressAngle.radians))
    }
    
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        if progress > 0.0 {
            path.addEllipse(in: CGRect(
                                x: position.x,
                                y: position.y,
                                width: rect.size.width,
                                height: rect.size.height))
        }
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
    
    @State var color: Color = .brightGreen
    @State var tipColor: Color? = nil
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            ActivityRing(
                progress: progress,
                tipShadowColor: .clear
            )
            .onReceive(timer) { _ in
                increment(&progress, maxProgress: 1)
            }

            ActivityRing(
                progress: progress1,
                radius: 20,
                thickness: 5,
                color: color,
                tipColor: tipColor,
                backgroundColor: Color.secondary.opacity(0.2),
                outlineColor: nil
            )
            .onReceive(timer) { _ in
                increment(&progress1)
                if progress1 <= 1 {
                    color = .brightGreen
                    tipColor = nil
                } else {
                    color = Color(darkR * 0.1)
                    tipColor = .brightRed
                }
            }

            ActivityRing(
                progress: progress2,
                color: .yellow,
                tipColor: .blue
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
                    radius: 100,
                    thickness: 23,
                    color: .darkRed,
                    tipColor: .brightRed,
                    backgroundColor: Color.brightRed.opacity(0.2),
                    outlineColor: nil
                )
                .onReceive(timer) { _ in
                    increment(&progress3)
                }

                ActivityRing(
                    progress: progress4,
                    radius: 75,
                    thickness: 23,
                    color: .darkGreen,
                    tipColor: .brightGreen,
                    backgroundColor: Color.brightGreen.opacity(0.2),
                    outlineColor: nil
                )
                .onReceive(timer) { _ in
                    increment(&progress4)
                }

                ActivityRing(
                    progress: progress5,
                    radius: 50,
                    thickness: 23,
                    color: .darkBlue,
                    tipColor: .brightBlue,
                    backgroundColor: Color.brightBlue.opacity(0.2),
                    outlineColor: nil
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
