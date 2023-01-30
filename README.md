# Emoji Art

This project was created as a samplie implementation of [SwiftUI Drag-and-Drop](https://github.com/hellojoelhuber/swiftui-drag-and-drop) library. This README is a mirror of my [personal website](https://www.joelhuber.com/documentation/documentation-emoji-art/).

![Emoji Art Drag-And-Drop Demo](https://github.com/hellojoelhuber/swiftui-drag-and-drop/blob/main/assets/media/documentation-dragdrop-emoji-art-vertical-demo.gif)

# Overview.

The Emoji Art project was unique in a few ways:
* There was a single `DropReceiver`, the canvas.
* There were two different `Dragable` objects, the emoji-as-string and the emoji-on-canvas.
* This features a zoom gesture, which complicated how to check the drag state and whether a drop was successful.

## Protocol: Dragable

Despite two "different" `Dragable` objects, the protocol only needed to be applied to `String`.

```swift
extension String: Dragable { }
```

In the PaletteView, the emoji was already text. In the documentBody View, the `emoji.text` was extracted from the Emoji object. 

## ViewModifier: .dragable(...)

The palette and document applied the same `.dragable(object:onDragged:onDropObject:)` definition.

```swift
    Text(emoji)
        ...
        .dragable(object: emoji,
                  onDragged: emojiDragged,
                  onDropObject: emojiDropped)
```

#### onDragged

Both used the same `emojiDragged` method:

```swift
    private func emojiDragged(position: CGPoint) -> DragState {
        document.getDragState(position)
    }
```

The method `getDragState()` is complicated because of the zoom feature.

Without zoom, the method looks like:
```swift
func getDragState(_ location: CGPoint) -> DragState {
        if getCanvasDropArea()!.contains(emojiLocation) {
            return .accepted
        }
        return .rejected
    }
```

This works because the `CGRect` that is the canvas drop area and the `CGPoint` are both defined in the global coordinate space. However, once we zoom in or out, we need to convert the global coordinate space to the "canvas" coordinate space. The full function looks like this:

```
    func getDragState(_ location: CGPoint) -> DragState {
        let canvasArea = getCanvasDropArea()!
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
```

Note that this drag state check only uses two cases of `DragState`, .accepted and .rejected.

#### onDropObject

However, the behaviors differed with `emojiDropped`. The palette emoji wanted to be _added_ to the canvas on drop, and the "paintbrush" needed to return to the palette. The former requirement was satisfied by calling the `addEmoji` method on the ViewModel; the latter requirement was satisfied by always returning false. (See the note on `ViewModifier: .dragable(...)` in the documentation overview.)

```swift
    private func emojiDropped(emoji: Dragable, position: CGPoint) -> Bool {
        if document.getDragState(position) == .accepted {
            document.addEmoji(emoji as! String,
                                 at: position,
                                 size: 10)
        }
        return false
    }
```

The canvas emoji wanted to be _updated_ on drop and to remain stationary. The former requirement is satisfied by calling a different method on the ViewModel, `updateEmoji`; the latter is satisfied by returning `true` on successful drop, `false` otherwise. 

```swift
    private func emojiDropped(emoji: Dragable, position: CGPoint) -> Bool {
        if document.getDragState(position) == .accepted {
            document.updateEmoji(emoji as! EmojiArtCanvas.Emoji,
                                 at: position,
                                 size: 10)
            return true
        }
        return false
    }
``` 

The two methods also wanted to share the dropped object differently. The drop from palette can share the `String` emoji because the `addEmoji` method will compute everything else it needs to know in order to create it. However, the `updateEmoji` method needs to know which Emoji to update, so the full emoji object is passed in as the object instead of only the `emoji.text`.

## Protocol: DropReceiver

The canvas was marked as the `DropReceiver`.

```swift
struct EmojiArtCanvas: DropReceiver {
    var dropArea: CGRect?
    ...
}
```

## Protocol: DropReceivableObservableObject

The `DropReceivableObservableObject` defines the `typealias DropReceivable` as the `EmojiArtCanvas` and a single `@Published var` for the canvas. It also defines two methods, `setDropArea(_:on:)` and `getCanvasDropArea()`. 

```swift
class EmojiDragAndDropViewModel: DropReceivableObservableObject {
    typealias DropReceivable = EmojiArtCanvas
    @Published private(set) var canvas: EmojiArtCanvas
    
    func setDropArea(_ dropArea: CGRect, on dropReceiver: EmojiArtCanvas) {
        canvas.updateDropArea(with: dropArea)
    }
    
    func getCanvasDropArea() -> CGRect {
        canvas.getDropArea()!
    }
    
    ...
}
```

The `getCanvasDropArea()` returns a CGRect and uses force-unwrapping on `canvas.getDropArea()!`. This is a choice. If the `.dropReceiver` ViewModifier does not set the drop area on the canvas, then the app likely has a more serious problem than force-unwrapping a `nil`.

## ViewModifier: .dropReceiver(for:model:)

The ViewModifier `.dropReceiver` was applied to the bottom layer of a `ZStack` which constructed the canvas and then emojis.

```swift
    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                    .frame(width: document.getCanvasWidth(), height: document.getCanvasHeight())
                    .dropReceiver(for: document.canvas, model: document)
                    .position(x: geometry.frame(in: .local).center.x,
                              y: geometry.frame(in: .local).center.y)
                ForEach(document.getEmojisOnCanvas()) { emoji in
                    Text(emoji.text)
                        .position(position(for: emoji, in: geometry))
                        .dragable(object: emoji,
                                  onDragged: emojiDragged,
                                  onDropObject: emojiDropped)
                }
            }
            .clipped()
        }
    }
```


