//  ATLFocusCursorView.h
//  Legacy Apple TV Reborn
//
//  Frutiger Aero focus indicator: a small mouse-cursor PNG image placed at
//  the bottom-right corner of the currently focused app tile.
//
//  Spec:
//    - Does NOT use the stock large focus frame.
//    - Cursor image: "FrutigerAeroCursor.png" from theme resources.
//    - Positioned at bottom-right of the focused view.
//    - Moves smoothly when focus changes.
//    - Must not be shown inside Kodi or media playback.
//    - Does NOT distort the underlying icon.
//
//  CONFIRMED APIs: UIView, UIImageView, CABasicAnimation — all CONFIRMED.

#import <UIKit/UIKit.h>

@interface ATLFocusCursorView : UIView

+ (instancetype)sharedCursor;

/// Move the cursor to the bottom-right of `focusedView` in its window coords.
/// Pass nil to hide the cursor.
- (void)moveToBRCornerOfView:(nullable UIView *)focusedView;

/// Instantly hide without animation (e.g. entering Kodi / playback).
- (void)hide;

/// Show again if previously hidden.
- (void)show;

@end
