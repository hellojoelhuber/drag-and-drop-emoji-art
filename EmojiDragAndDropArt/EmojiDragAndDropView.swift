//
//  EmojiDragAndDropView.swift
//  EmojiDragAndDropArt
//
//  Created by Joel Huber on 6/30/22.
//

import SwiftUI
import DragAndDrop

struct EmojiDragAndDropView: View {
    @StateObject var document = EmojiDragAndDropViewModel()
    private let defaultEmojiFontSize: CGFloat = 40
    
    @State private var steadyStateZoomScale: CGFloat = 1
    @GestureState private var gestureZoomScale: CGFloat = 1
    
    private var zoomScale: CGFloat {
        gestureZoomScale * steadyStateZoomScale
    }
    
    var body: some View {
        VStack(spacing: 0) {
            documentBody
            palette
                .environmentObject(document)
        }
        .background(Color.gray)
    }
    
    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                    .scaleEffect(zoomScale)
                    .frame(width: document.getCanvasWidth(), height: document.getCanvasHeight())
                    .dropReceiver(for: document.canvas, model: document)
                    .position(x: geometry.frame(in: .local).center.x,
                              y: geometry.frame(in: .local).center.y)
                ForEach(document.getEmojisOnCanvas()) { emoji in
                    Text(emoji.text)
                        .scaleEffect(zoomScale)
                        .position(position(for: emoji, in: geometry))
                        .dragable(object: emoji,
                                  onDragged: onDragCanvasEmoji,
                                  onDropObject: onDropCanvasEmoji)
                }
            }
            .clipped()
            .gesture(zoomGesture())
        }
    }

    var palette: some View {
            EmojisPaletteView(defaultEmojiFontSize: defaultEmojiFontSize)
                .font(.system(size: defaultEmojiFontSize))
                .padding()
                .background()
    }
    
    // MARK: - Methods
    
    private func onDragCanvasEmoji(position: CGPoint) -> DragState {
        document.getDragState(position)
    }
    
    private func onDropCanvasEmoji(emoji: Dragable, position: CGPoint) -> Bool {
        if document.getDragState(position) == .accepted {
            document.updateEmoji(emoji as! EmojiArtCanvas.Emoji,
                                 at: position,
                                 size: 10)
            return true
        }
        return false
    }
    

    private func position(for emoji: EmojiArtCanvas.Emoji, in geometry: GeometryProxy) -> CGPoint {
        convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry)
    }
    private func convertFromEmojiCoordinates(_ location: (x: Double, y: Double), in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        return CGPoint(
            x: center.x + CGFloat(location.x) * zoomScale,
            y: center.y + CGFloat(location.y) * zoomScale
        )
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, ourGestureStateInOut, transaction in
                ourGestureStateInOut = latestGestureScale
            }
            .onEnded { gestureScaleAtEnd in
                steadyStateZoomScale *= gestureScaleAtEnd
                document.setZoomScale(to: gestureZoomScale * steadyStateZoomScale)
            }
    }
}

struct EmojiDragAndDropView_Previews: PreviewProvider {
    struct Preview: View {
        var body: some View {
            EmojiDragAndDropView()
        }
    }
    static var previews: some View {
        Preview()
    }
}
