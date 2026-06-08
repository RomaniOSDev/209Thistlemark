import SwiftUI

struct KitchenConverterView: View {
    @State private var amountText = "1"
    @State private var fromUnit: KitchenUnit = .cup
    @State private var toUnit: KitchenUnit = .g
    @State private var density: DensityProfile = .flour
    @State private var resultText = "Result will appear here"
    @State private var helperError: String?
    @State private var shake: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(spacing: 14) {
                        AppArtworkView(name: "CalmConverter", height: 140)

                        AppCard {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionTitleRow(title: "Amount", subtitle: "Enter the value you want to convert")
                                TextField("Enter amount", text: $amountText)
                                    .keyboardType(.decimalPad)
                                    .modifier(ShakeEffect(animatableData: shake))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 11)
                                    .appDepthCard(cornerRadius: 12, elevated: false)
                                HStack(spacing: 8) {
                                    quickAmountButton("0.5")
                                    quickAmountButton("1")
                                    quickAmountButton("2")
                                    quickAmountButton("5")
                                }
                                if let helperError {
                                    Text(helperError)
                                        .font(.footnote)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        AppCard {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionTitleRow(title: "Units", subtitle: "Choose source, target, and density")
                                Picker("From", selection: $fromUnit) {
                                    ForEach(KitchenUnit.allCases) { unit in
                                        Text(unit.title).tag(unit)
                                    }
                                }
                                Picker("To", selection: $toUnit) {
                                    ForEach(KitchenUnit.allCases) { unit in
                                        Text(unit.title).tag(unit)
                                    }
                                }
                                Picker("Ingredient density", selection: $density) {
                                    ForEach(DensityProfile.allCases) { item in
                                        Text(item.rawValue).tag(item)
                                    }
                                }
                            }
                        }

                        Button("Convert") {
                            FeedbackManager.tap()
                            convert()
                        }
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(
                            LinearGradient(
                                colors: [Color("AppPrimary"), Color("AppAccent")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 4)

                        AppCard {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionTitleRow(title: "Output", subtitle: "Kitchen-adjusted conversion result")
                                Text(resultText)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                    .font(.title3.bold())
                                    .lineLimit(2)
                            }
                        }
                    }
                    .padding(14)
                }
            }
            .navigationTitle("Unit Converter")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func quickAmountButton(_ value: String) -> some View {
        Button {
            FeedbackManager.tap()
            amountText = value
        } label: {
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("AppTextPrimary"))
                .frame(maxWidth: .infinity, minHeight: 34)
                .background(
                    LinearGradient(
                        colors: [Color("AppPrimary").opacity(0.95), Color("AppAccent").opacity(0.82)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }

    private func convert() {
        guard let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")), amount >= 0 else {
            helperError = "Please enter a valid numeric amount."
            shake += 1
            FeedbackManager.warning()
            return
        }

        guard let result = convert(amount: amount, from: fromUnit, to: toUnit, density: density.gramsPerML) else {
            helperError = "This unit path is not supported."
            shake += 1
            FeedbackManager.warning()
            return
        }

        helperError = nil
        resultText = String(format: "%.2f %@ (%@)", result, toUnit.title, density.rawValue)
        FeedbackManager.save()
    }

    private func convert(amount: Double, from: KitchenUnit, to: KitchenUnit, density: Double) -> Double? {
        if from == to { return amount }

        if let fromVolume = from.volumeInML, let toVolume = to.volumeInML {
            let ml = amount * fromVolume
            return ml / toVolume
        }
        if let fromWeight = from.weightInGrams, let toWeight = to.weightInGrams {
            let grams = amount * fromWeight
            return grams / toWeight
        }

        if let fromVolume = from.volumeInML, let toWeight = to.weightInGrams {
            let ml = amount * fromVolume
            let grams = ml * density
            return grams / toWeight
        }
        if let fromWeight = from.weightInGrams, let toVolume = to.volumeInML {
            let grams = amount * fromWeight
            let ml = grams / density
            return ml / toVolume
        }
        return nil
    }
}
