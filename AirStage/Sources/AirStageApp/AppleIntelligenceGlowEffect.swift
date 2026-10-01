import SwiftUI

struct AppleIntelligenceGlowEffect: View {
    var cornerRadius: CGFloat
    var gradientColors: [Color]

    @State private var gradientStops: [Gradient.Stop] = []
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    init(cornerRadius: CGFloat = 16, colors: [Color] = [Color(red: 188/255, green: 130/255, blue: 243/255), Color(red: 245/255, green: 185/255, blue: 234/255), Color(red: 100/255, green: 150/255, blue: 255/255)]) {
        self.cornerRadius = cornerRadius
        self.gradientColors = colors
        self._gradientStops = State(initialValue: Self.generateGradientStops(colors: colors))
    }

    static func generateGradientStops(colors: [Color]) -> [Gradient.Stop] {
        var stops: [Gradient.Stop] = []
        for color in colors {
            stops.append(Gradient.Stop(color: color, location: Double.random(in: 0...1)))
        }
        // Duplicate first color to ensure smooth wrap around
        if let first = colors.first {
             stops.append(Gradient.Stop(color: first, location: Double.random(in: 0...1)))
        }
        return stops.sorted { $0.location < $1.location }
    }

    var body: some View {
        ZStack {
            // Base sharp outline
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(AngularGradient(stops: gradientStops, center: .center), lineWidth: 2)

            // Inner soft glow
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(AngularGradient(stops: gradientStops, center: .center), lineWidth: 4)
                .blur(radius: 4)

            // Middle glow
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(AngularGradient(stops: gradientStops, center: .center), lineWidth: 6)
                .blur(radius: 12)
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.6)) {
                gradientStops = Self.generateGradientStops(colors: gradientColors)
            }
        }
    }
}
