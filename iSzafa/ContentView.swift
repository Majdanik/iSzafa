import SwiftUI
import SwiftData
import PhotosUI
import Vision
import CoreImage.CIFilterBuiltins

// ==========================================
// 1. MODELE DANYCH
// ==========================================

enum ItemCategory: String, Codable, CaseIterable {
    case hat = "Nakrycia głowy"
    case glasses = "Okulary"
    case top = "Góra"
    case bottom = "Spodnie / Spódnice"
    case shoes = "Obuwie"
    case accessories = "Akcesoria"
}

@Model
class ClothingItem {
    var id: UUID
    @Attribute(.externalStorage) var imageData: Data
    var dateAdded: Date
    var categoryRawValue: String
    

    var category: ItemCategory {
        if let newCategory = ItemCategory(rawValue: categoryRawValue) {
            return newCategory
        }
        switch categoryRawValue {
        case "Czapka": return .hat
        case "Okulary": return .glasses
        case "Top": return .top
        case "Dół": return .bottom
        case "Buty": return .shoes
        case "Akcesoria": return .accessories
        default: return .top
        }
    }
    
    init(imageData: Data, category: ItemCategory) {
        self.id = UUID()
        self.imageData = imageData
        self.dateAdded = Date()
        self.categoryRawValue = category.rawValue
    }
}

struct CanvasItem: Identifiable {
    let id = UUID()
    let clothing: ClothingItem
    var offset: CGSize = .zero
    var scale: CGFloat = 1.0
    var rotation: Angle = .zero
}

// ==========================================
// WIDOK POMOCNICZY DLA UBRAŃ
// ==========================================
struct ClothingItemImageView: View {
    let uiImage: UIImage
    let category: ItemCategory
    
    var body: some View {
        
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFit()
    }
}

// ==========================================
// 2. GŁÓWNY WIDOK
// ==========================================
struct ContentView: View {
    var body: some View {
        TabView {
            WardrobeView()
                .tabItem { Label("Szafa", systemImage: "tshirt") }
            
            CreatorView()
                .tabItem { Label("Kreator", systemImage: "wand.and.stars") }
        }
    }
}

// ==========================================
// 3. WIDOK SZAFY (Skaner + Baza)
// ==========================================
struct WardrobeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClothingItem.dateAdded, order: .reverse) private var closetItems: [ClothingItem]
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var processedImage: UIImage?
    @State private var isProcessing = false
    @State private var selectedCategory: ItemCategory = .top
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // --- Skaner ---
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 300)
                        
                        if isProcessing {
                            VStack {
                                ProgressView()
                                Text("Wyciskanie z tła...").font(.caption).padding(.top, 5)
                            }
                        } else if let image = processedImage {
                            ClothingItemImageView(uiImage: image, category: selectedCategory)
                                .frame(height: 250)
                                .shadow(radius: 5)
                        } else {
                            ContentUnavailableView("Zeskanuj ubranie", systemImage: "camera")
                        }
                    }
                    .padding(.horizontal)
                    
                    // --- Wybór Kategorii ---
                    if processedImage != nil {
                        VStack(alignment: .leading) {
                            Text("Wybierz kategorię:").font(.subheadline).foregroundColor(.secondary).padding(.horizontal)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(ItemCategory.allCases, id: \.self) { cat in
                                        Text(cat.rawValue)
                                            .padding(.horizontal, 16).padding(.vertical, 8)
                                            .background(selectedCategory == cat ? Color.blue : Color.gray.opacity(0.2))
                                            .foregroundColor(selectedCategory == cat ? .white : .primary)
                                            .clipShape(Capsule())
                                            .onTapGesture { selectedCategory = cat }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // --- Przyciski ---
                    HStack(spacing: 15) {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Label("Galeria", systemImage: "photo.on.rectangle")
                                .padding().frame(maxWidth: .infinity)
                                .background(Color.blue).foregroundColor(.white).cornerRadius(10)
                        }
                        
                        if processedImage != nil {
                            Button(action: saveClothingItem) {
                                Label("Zapisz", systemImage: "checkmark")
                                    .padding().frame(maxWidth: .infinity)
                                    .background(Color.green).foregroundColor(.white).cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider().padding(.vertical)
                    
                    // --- Siatka Ubrań (BRAK TŁA) ---
                    Text("Twoja Szafa (\(closetItems.count))")
                        .font(.title2).bold().frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 15) {
                        ForEach(closetItems) { item in
                            if let uiImage = UIImage(data: item.imageData) {
                                VStack {
                                    ClothingItemImageView(uiImage: uiImage, category: item.category)
                                        .frame(height: 100) // W szafie wszystkie rzeczy są równe (100)
                                        .shadow(color: .black.opacity(0.15), radius: 5)
                                    
                                    Button(role: .destructive) { deleteItem(item) } label: {
                                        Image(systemName: "trash").foregroundColor(.red).padding(5)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Moja Szafa")
            .onChange(of: selectedItem) { processPhoto() }
        }
    }
    
    func saveClothingItem() {
        guard let image = processedImage, let imageData = image.pngData() else { return }
        let newItem = ClothingItem(imageData: imageData, category: selectedCategory)
        modelContext.insert(newItem)
        processedImage = nil
        selectedItem = nil
    }
    func deleteItem(_ item: ClothingItem) { modelContext.delete(item) }
    
    func processPhoto() {
        Task {
            if let data = try? await selectedItem?.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) { removeBackground(from: uiImage) }
        }
    }
    func removeBackground(from inputImage: UIImage) {
        isProcessing = true
        DispatchQueue.global(qos: .userInitiated).async {
            guard let ciImage = CIImage(image: inputImage) else { return }
            let request = VNGenerateForegroundInstanceMaskRequest()
            let handler = VNImageRequestHandler(ciImage: ciImage)
            do {
                try handler.perform([request])
                guard let result = request.results?.first else {
                    DispatchQueue.main.async { isProcessing = false }; return
                }
                let maskPixelBuffer = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
                let maskImage = CIImage(cvPixelBuffer: maskPixelBuffer)
                let blendFilter = CIFilter.blendWithMask()
                blendFilter.inputImage = ciImage
                blendFilter.maskImage = maskImage
                blendFilter.backgroundImage = CIImage.empty()
                if let output = blendFilter.outputImage, let cgImage = CIContext().createCGImage(output, from: output.extent) {
                    let finalImage = UIImage(cgImage: cgImage)
                    DispatchQueue.main.async { self.processedImage = finalImage; self.isProcessing = false }
                }
            } catch {
                DispatchQueue.main.async { isProcessing = false }
            }
        }
    }
}

// ==========================================
// 4. WIDOK KREATORA
// ==========================================
struct CreatorView: View {
    @Query private var allItems: [ClothingItem]
    @State private var accessoryCanvasItems: [CanvasItem] = []
    
    var canvasContent: some View {
        ZStack {
            Color.gray.opacity(0.05).edgesIgnoringSafeArea(.all)
            
            ZStack {
                CategorySlotView(category: .shoes, items: allItems.filter { $0.category == .shoes }, defaultY: 200)
                CategorySlotView(category: .bottom, items: allItems.filter { $0.category == .bottom }, defaultY: 80)
                CategorySlotView(category: .top, items: allItems.filter { $0.category == .top }, defaultY: -70)
                CategorySlotView(category: .glasses, items: allItems.filter { $0.category == .glasses }, defaultY: -180)
                CategorySlotView(category: .hat, items: allItems.filter { $0.category == .hat }, defaultY: -230)
            }
            
            ForEach($accessoryCanvasItems) { $item in
                AccessoryDraggableView(item: $item)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                canvasContent.clipped()
                
                // --- SZUFLADA NA AKCESORIA ---
                VStack {
                    Spacer()
                    let accessories = allItems.filter { $0.category == .accessories }
                    if !accessories.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Dodaj Akcesoria:").font(.caption).bold().padding(.horizontal)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(accessories) { item in
                                        if let uiImage = UIImage(data: item.imageData) {
                                            Image(uiImage: uiImage)
                                                .resizable().scaledToFit().frame(width: 50, height: 50)
                                                .shadow(radius: 2)
                                                .padding(5)
                                                .onTapGesture {
                                                    accessoryCanvasItems.append(CanvasItem(clothing: item))
                                                }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 10)
                        .background(Color(UIColor.systemBackground).shadow(radius: 10))
                    }
                }
            }
            .navigationTitle("Kreator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Usuń akcesoria") { accessoryCanvasItems.removeAll() }
                        .font(.caption)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(
                        item: generateSnapshot(),
                        preview: SharePreview("Mój Outfit", image: generateSnapshot())
                    ) {
                        Image(systemName: "square.and.arrow.up").font(.headline)
                    }
                }
            }
        }
    }
    
    @MainActor
    private func generateSnapshot() -> Image {
        let exportView = ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            canvasContent
        }.frame(width: 400, height: 600)
        
        let renderer = ImageRenderer(content: exportView)
        renderer.scale = 2.0
        
        if let uiImage = renderer.uiImage { return Image(uiImage: uiImage) }
        return Image(systemName: "photo")
    }
}

// ==========================================
// 5. POJEDYNCZE PIĘTRO W KREATORZE
// ==========================================
struct CategorySlotView: View {
    let category: ItemCategory
    let items: [ClothingItem]
    let defaultY: CGFloat
    
    @State private var currentIndex: Int = 0
    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    
    @State private var currentDrag: CGSize = .zero
    @State private var currentMagnification: CGFloat = 1.0
    
    var body: some View {
        HStack {
            Button(action: { changeItem(-1) }) {
                Image(systemName: "chevron.compact.left")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(items.isEmpty ? .clear : .gray.opacity(0.5))
            }
            .padding(.leading, 10)
            .disabled(items.isEmpty)
            
            Spacer()
            
            if items.isEmpty {
                Text("Brak: \(category.rawValue)")
                    .font(.caption).foregroundColor(.gray.opacity(0.4))
                    .frame(height: defaultHeight())
            } else {
                if let uiImage = UIImage(data: items[currentIndex].imageData) {
                    ClothingItemImageView(uiImage: uiImage, category: category)
                        .frame(height: defaultHeight())
                        .scaleEffect(scale * currentMagnification)
                        .offset(x: offset.width + currentDrag.width,
                                y: offset.height + currentDrag.height)
                        .gesture(
                            DragGesture()
                                .onChanged { value in currentDrag = value.translation }
                                .onEnded { value in
                                    offset.width += value.translation.width
                                    offset.height += value.translation.height
                                    currentDrag = .zero
                                }
                        )
                        .simultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in currentMagnification = value }
                                .onEnded { value in
                                    scale *= value
                                    currentMagnification = 1.0
                                }
                        )
                }
            }
            
            Spacer()
            
            Button(action: { changeItem(1) }) {
                Image(systemName: "chevron.compact.right")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(items.isEmpty ? .clear : .gray.opacity(0.5))
            }
            .padding(.trailing, 10)
            .disabled(items.isEmpty)
        }
        .offset(y: defaultY)
    }
    
    func changeItem(_ step: Int) {
        if items.isEmpty { return }
        currentIndex = (currentIndex + step + items.count) % items.count
        withAnimation(.spring()) {
            offset = .zero
            scale = 1.0
        }
    }
    
    func defaultHeight() -> CGFloat {
        switch category {
        case .hat, .glasses: return 80
        case .top, .bottom: return 180
        case .shoes: return 200
        default: return 100
        }
    }
}

// ==========================================
// 6. WIDOK DLA AKCESORIÓW
// ==========================================
struct AccessoryDraggableView: View {
    @Binding var item: CanvasItem
    @State private var currentDrag: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var currentRotation: Angle = .zero
    
    var body: some View {
        if let uiImage = UIImage(data: item.clothing.imageData) {
            ClothingItemImageView(uiImage: uiImage, category: item.clothing.category)
                .frame(width: 100)
                .scaleEffect(item.scale * currentScale)
                .rotationEffect(item.rotation + currentRotation)
                .offset(x: item.offset.width + currentDrag.width,
                        y: item.offset.height + currentDrag.height)
                .gesture(
                    DragGesture()
                        .onChanged { val in currentDrag = val.translation }
                        .onEnded { val in
                            item.offset.width += val.translation.width
                            item.offset.height += val.translation.height
                            currentDrag = .zero
                        }
                )
                .simultaneousGesture(
                    MagnificationGesture()
                        .onChanged { val in currentScale = val }
                        .onEnded { val in
                            item.scale *= val
                            currentScale = 1.0
                        }
                )
                .simultaneousGesture(
                    RotationGesture()
                        .onChanged { val in currentRotation = val }
                        .onEnded { val in
                            item.rotation += val
                            currentRotation = .zero
                        }
                )
        }
    }
}
