import SwiftUI
import CoreML
import Vision

struct ImageClassificationView: View {
    @State private var image: UIImage?
    @State private var classLabel: String = ""
    @State private var classLabelProbs: [String: Double] = [:]
    @State private var isCameraVisible = false
    @State private var isTakingPicture = false


    var body: some View {
        ZStack {
            if isCameraVisible {
                CameraPreview(isTakingPicture: $isTakingPicture)
            } else {
                VStack {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding()
                    } else {
                        Button("Take a picture") {
                            self.isCameraVisible = true
                        }
                        .padding()
                    }

                    if !classLabel.isEmpty {
                        Button("Show result") {
                            self.isCameraVisible = false
                        }
                        .padding()
                    }
                }
                .onAppear {
                    self.image = UIImage(named: "example")
                    if let image = self.image {
                        self.classifyImage(image)
                    }
                }
            }
        }
    }

    func classifyImage(_ image: UIImage) {
        guard let model = try? VNCoreMLModel(for: vegetables().model) else {
            print("Failed to load Core ML model.")
            return
        }

        let request = VNCoreMLRequest(model: model) { [self] request, error in
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                print("Failed to classify image: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            let classLabelProbs = Dictionary(uniqueKeysWithValues: zip(results.map({ $0.identifier }), results.map({ Double($0.confidence) })))

            DispatchQueue.main.async {
                self.classLabel = topResult.identifier
                self.classLabelProbs = classLabelProbs
            }
        }


        guard let ciImage = CIImage(image: image) else {
            print("Failed to convert UIImage to CIImage.")
            return
        }

        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform classification request: \(error.localizedDescription)")
        }
    }

}

struct ResultView: View {
    @Binding var predictions: [String: Double]

    var body: some View {
        NavigationView {
            List {
                ForEach(predictions.sorted(by: { $0.value > $1.value }), id: \.key) { prediction in
                    HStack {
                        Text(prediction.key)
                            .font(.headline)
                        Spacer()
                        Text("\(prediction.value, specifier: "%.2f")")
                            .font(.subheadline)
                            .foregroundColor(prediction.value == predictions.values.max() ? .green : .secondary)
                    }
                }
            }
            .navigationBarTitle("Predictions")
        }
    }
}
