// 1. Add a TimelineView to drive the animation
TimelineView(.animation) { timeline in
    let elapsed = timeline.date.timeIntervalSince1970

    RoundedRectangle(cornerRadius: 28)
        .strokeBorder(
            LinearGradient(
                colors: [K.cyan, K.purple, K.magenta],
                startPoint: .leading,
                endPoint: .trailing
            ),
            lineWidth: 3
        )
        .colorEffect(
            ShaderLibrary.orbitSpark(
                .float2(size),       // button size
                .float(elapsed),     // time
                .float(3.0),         // border width
                .float(28.0)         // corner radius
            )
        )
}
