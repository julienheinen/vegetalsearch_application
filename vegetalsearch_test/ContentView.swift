import SwiftUI
import CoreML
import Vision

struct ContentView: View {
    @State private var isTakingPicture = false
    @State private var image: UIImage?
    @State private var classLabel = ""
    @State private var classLabelProbs: [String: Double] = [:]
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false

    var body: some View {
        ZStack {
            CameraPreview(isTakingPicture: $isTakingPicture, image: $image)
                .edgesIgnoringSafeArea(.all)


            VStack {
                Spacer()

                HStack {
                    Button(action: {
                        self.isTakingPicture = true
                    }) {
                        Text("Take Picture")
                            .font(.headline)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }

                    Button(action: {
                        self.showingImagePicker = true
                    }) {
                        Image(systemName: "photo.fill")
                            .font(.headline)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                }

                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding()

                    VStack(alignment: .leading) {
                        Text("Classification:")
                            .font(.headline)

                        Text(classLabel)
                            .font(.largeTitle)
                            .foregroundColor(.green)

                        ForEach(Array(classLabelProbs.keys.sorted()), id: \.self) { key in
                            HStack {
                                Text(key)
                                    .font(.headline)

                                Spacer()

                                Text("\(classLabelProbs[key] ?? 0, specifier: "%.2f")")
                                    .font(.headline)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: self.$selectedImage, classifyImage: { image in
                self.classifyImage(image)
            })
        }        .onAppear {
            if let exampleImage = UIImage(named: "example") {
                self.classifyImage(exampleImage)
            } else {
                print("Failed to find example image")
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

        let context = CIContext()
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform classification request: \(error.localizedDescription)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
