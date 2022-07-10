
import SwiftUI
import DragAndDrop

struct EmojiArtCanvas: DropReceiver {
    var dropArea: CGRect?
    var canvasWidth: Double
    var canvasHeight: Double
    
    var emojis = [Emoji]()
    
    struct Emoji: Identifiable, Hashable, Dragable {
        var id: Int
        let text: String
        var x: Double // offset from the center
        var y: Double // offset from the center
        var size: Int
        
        fileprivate init(id: Int, text: String, x: Double, y: Double, size: Int) {
            self.id = id
            self.text = text
            self.x = x
            self.y = y
            self.size = size
        }
    }
    
    init(width: Double, height: Double) {
        self.canvasWidth = width
        self.canvasHeight = height
    }
    
    private var uniqueEmojiId = 0
    mutating func addEmoji(_ text: String, at location: (x: Double, y: Double), size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(id: uniqueEmojiId,
                            text: text,
                            x: location.x,
                            y: location.y,
                            size: size)
        )
    }
    
    mutating func updateEmoji(_ id: Int, to location: (x: Double, y: Double), to size: Int) {
        let index = emojis.firstIndex(where: { $0.id == id })!
        emojis[index].x = location.x
        emojis[index].y = location.y
        emojis[index].size = size
    }
}
