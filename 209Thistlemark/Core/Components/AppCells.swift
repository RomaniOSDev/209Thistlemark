import SwiftUI

struct AppCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(14)
            .appDepthCard(cornerRadius: 16, elevated: false)
    }
}

struct SectionTitleRow: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color("AppTextPrimary"))
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MetricCell: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .foregroundStyle(Color("AppAccent"))
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(Color("AppTextPrimary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
        .padding(12)
        .appDepthCard(cornerRadius: 14, elevated: false)
    }
}

struct SettingsActionCell: View {
    let title: String
    let icon: String
    let tint: Color
    var destructive = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 24)
            Text(title)
                .foregroundStyle(destructive ? Color.red : Color("AppTextPrimary"))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .frame(maxWidth: .infinity, minHeight: 46)
        .padding(.horizontal, 10)
        .appDepthCard(cornerRadius: 12, elevated: false)
    }
}

struct AppArtworkView: View {
    let name: String
    var height: CGFloat = 180

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color("AppTextSecondary").opacity(0.12), lineWidth: 1)
            )
    }
}

struct RankedIngredientCell: View {
    let rank: Int
    let name: String
    let count: Int

    var body: some View {
        HStack(spacing: 10) {
            Text("#\(rank)")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("AppTextPrimary"))
                .frame(width: 34, height: 28)
                .background(Color("AppPrimary").opacity(0.7), in: Capsule())
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                Text("\(count) views")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
