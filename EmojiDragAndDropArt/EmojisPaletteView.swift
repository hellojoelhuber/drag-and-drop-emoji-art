//
//  EmojisPaletteView.swift
//  EmojiDragAndDropArt
//
//  Created by Joel Huber on 7/3/22.
//

import SwiftUI
import DragAndDrop

struct EmojisPaletteView: View {
    @EnvironmentObject var document: EmojiDragAndDropViewModel
    
    let defaultEmojiFontSize: CGFloat
    
    var body: some View {
        HStack {
            ForEach(document.getEmojiPalette().map { String($0) }, id: \.self) { emoji in
                Text(emoji)
                    .frame(minWidth: defaultEmojiFontSize)
                    .dragable(object: emoji,
                              onDragged: onDragPaletteEmoji,
                              onDropObject: onDropPaletteEmoji)
            }
        }
    }
    
    
    private func onDragPaletteEmoji(position: CGPoint) -> DragState {
        document.getDragState(position)
    }
    
    private func onDropPaletteEmoji(emoji: Dragable, position: CGPoint) -> Bool {
        if document.getDragState(position) == .accepted {
            document.addEmoji(emoji as! String,
                                 at: position,
                                 size: 10)
        }
        return false
    }
}

struct EmojisPaletteView_Previews: PreviewProvider {
    struct Preview: View {
        @StateObject var model = EmojiDragAndDropViewModel()
        
        var body: some View {
            EmojisPaletteView(defaultEmojiFontSize: 40)
                .environmentObject(model)
        }
    }
    
    static var previews: some View {
        Preview()
    }
}
