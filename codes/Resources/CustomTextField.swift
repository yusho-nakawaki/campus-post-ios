//
//  CustomTextField.swift
//  match
//
//  on 2021/03/03.
//

import UIKit

class CustomTextField: UITextField {

    // 入力カーソル非表示
    override func caretRect(for position: UITextPosition) -> CGRect {
        return CGRect.zero
    }
    // 範囲選択カーソル非表示
    override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        return []
    }

    // コピー・ペースト・選択等のメニュー非表示
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }
    

}
