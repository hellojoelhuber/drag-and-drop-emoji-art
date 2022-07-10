
import SwiftUI
import DragAndDrop

final class EmojiDragAndDropViewModel: DropReceivableObservableObject {
    typealias DropReceivable = EmojiArtCanvas
    @Published private(set) var canvas: EmojiArtCanvas
    private let defaultEmojiPalette = "🐶🐱🐭🐹🐼🐻🦊🐸🐯🐨🐮🐷🐵"
    private var zoomScale: Double = 1
    
    func setDropArea(_ dropArea: CGRect, on dropReceiver: EmojiArtCanvas) {
        canvas.updateDropArea(with: dropArea)
    }
    
    init() {
        canvas = EmojiArtCanvas(width: 300, height: 200)
    }

    func getCanvasWidth() -> Double {
        canvas.canvasWidth
    }
    
    func getCanvasHeight() -> Double {
        canvas.canvasHeight
    }
        
    func getEmojisOnCanvas() -> [EmojiArtCanvas.Emoji] {
        canvas.emojis
    }
    
    func getEmojiPalette() -> String {
        defaultEmojiPalette
    }
    
    func getCanvasDropArea() -> CGRect {
        canvas.getDropArea()!
    }
    
    func setZoomScale(to zoom: Double) {
        zoomScale = zoom
    }
    
    func convertToEmojiCoordinates(_ location: CGPoint, in canvas: CGRect) -> (x: Double, y: Double) {
        let center = CGPoint(x: canvas.midX, y: canvas.midY)
        let location = CGPoint(
            x: location.x - center.x,
            y: location.y - center.y
        )

        return ((location.x), (location.y))
    }
    
    func getDragState(_ location: CGPoint) -> DragState {
        let canvasArea = getCanvasDropArea()
        let emojiCoordX = convertToEmojiCoordinates(canvasArea.center, in: canvasArea).x
        let emojiCoordY = convertToEmojiCoordinates(canvasArea.center, in: canvasArea).y
        let canvasMinX = emojiCoordX - (getCanvasWidth() / 2 * zoomScale)
        let canvasMaxX = emojiCoordX + (getCanvasWidth() / 2 * zoomScale)
        let canvasMinY = emojiCoordY - (getCanvasHeight() / 2 * zoomScale)
        let canvasMaxY = emojiCoordY + (getCanvasHeight() / 2 * zoomScale)
        
        let emojiLocation = convertToEmojiCoordinates(location, in: canvasArea)
        
        if canvasMinX...canvasMaxX ~= emojiLocation.x
            && canvasMinY...canvasMaxY ~= emojiLocation.y {
            return .accepted
        }
        
        return .rejected
    }
    
    func addEmoji(_ emoji: String, at location: CGPoint, size: CGFloat) {
        let emojiLocation = convertToEmojiCoordinates(location, in: getCanvasDropArea())
        canvas.addEmoji(emoji, at: (x: emojiLocation.x / zoomScale, y: emojiLocation.y / zoomScale), size: Int(size))
    }
    
    func updateEmoji(_ emoji: EmojiArtCanvas.Emoji, at location: CGPoint, size: CGFloat) {
        let emojiLocation = convertToEmojiCoordinates(location, in: getCanvasDropArea())
        canvas.updateEmoji(emoji.id, to: (x: emojiLocation.x / zoomScale, y: emojiLocation.y / zoomScale), to: Int(size))
    }
}
