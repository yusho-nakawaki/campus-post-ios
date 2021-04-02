//
//  ChatViewController.swift
//  Study_Match
//
//  on 2020/10/29.
//  Copyright © 2020 yusho. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import CropViewController


struct Message: MessageType {
    
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var isRead: Bool
    var kind: MessageKind
    
}

struct Sender: SenderType {
    public var photoURL: String
    public var senderId: String
    public var displayName: String
}

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

extension MessageKind {
    var messageKingString: String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributedText"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "linkPreview"
        case .custom(_):
            return "custom"
        }
    }
}


final class ChatViewController: MessagesViewController {
    
    public var isNewConversation = false
    public let partnerSafeEmail: String
    public let partnerName: String
    public var conversationId: String?
    private var messages = [Message]()
    private var partnerPhotoUrl: URL?
    private var messageIdForImage = ""
    private var partnerNameForImage = ""
    private var conversationIdforImage = ""
    private var canSendMessage = 0 // 0がブロックしていない, 1がブロックした, 2がブロックされた
    
    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeMyEmail = DatabaseManager.safeEmail(emailAddress: email)
        // senderIdで自分が送ったmessageか、送られてきたmessageかをMessageKitが判断している
        return Sender(photoURL: "",
                      senderId: safeMyEmail,
                      displayName: "Me")
    }
    private let dammySender = Sender(photoURL: "", senderId: "1", displayName: "other")
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter
    }()
    
    private let dateFormatterForChat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
    
    private let dateFormatterForChatCell: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()


    
    init(partnerEmail: String, partnerName: String, conversationId: String?) {
        self.partnerSafeEmail = partnerEmail
        self.partnerName = partnerName
        self.conversationId = conversationId
        
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: " ← ",
                                                           style: .done,
                                                           target: self,
                                                           action: #selector(popToVC))
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.tintColor = UIColor(named: "gentle")
        navigationController?.navigationBar.barTintColor = UIColor(named: "appBackground")
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        
        inputBarLeft()
        
        
        if let conversationId = conversationId {
            startListenMessage(id: conversationId)
        }
        
        // 自分のアバターを消して、メッセージを右に少しずらす
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.setMessageOutgoingAvatarSize(.zero)
            layout.setMessageOutgoingMessageTopLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)))
            layout.setMessageOutgoingMessageBottomLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)))
        }

        // 一番最初に送るmessageCellが隠れないように
        messagesCollectionView.contentInset = UIEdgeInsets(top: 44, left: 0, bottom: 0, right: 0)
        
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(dismissSelf))
        rightSwipe.direction = .right
        messagesCollectionView.addGestureRecognizer(rightSwipe)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        messageInputBar.inputTextView.becomeFirstResponder()
        messageInputBar.inputTextView.layer.cornerRadius = 7
        messageInputBar.inputTextView.backgroundColor = .secondarySystemBackground
        messagesCollectionView.reloadData()

        messagesCollectionView.scrollToBottom(animated: false)
        
        checkBlock()
        
    }
    
    @objc private func popToVC() {
        navigationController?.popViewController(animated: true)
    }
    
    
    // 写真などを送るために、inputbarの左に追加
    private func inputBarLeft() {
        let button1 = InputBarButtonItem()
        button1.setSize(CGSize(width: 35, height: 35), animated: false)
        button1.setImage(UIImage(systemName: "camera"), for: .normal)
        button1.tintColor = .label
        button1.onTouchUpInside { [weak self] _ in
            if self?.canSendMessage != 0 {
                if self?.canSendMessage == 1 {
                    self?.alertUserError(alertMessage: "\(self?.partnerName ?? "")さんをブロックしているため、メッセージを送信できません。")
                    return
                }
                if self?.canSendMessage == 2 {
                    self?.alertUserError(alertMessage: "\(self?.partnerName ?? "")さんにブロックされているため、メッセージを送信できません。")
                    return
                }
            }
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = false
            self?.present(picker, animated: true)
        }
        let button2 = InputBarButtonItem()
        button2.setSize(CGSize(width: 35, height: 35), animated: false)
        button2.setImage(UIImage(systemName: "photo"), for: .normal)
        button2.tintColor = .label
        button2.onTouchUpInside { [weak self] _ in
            if self?.canSendMessage != 0 {
                if self?.canSendMessage == 1 {
                    self?.alertUserError(alertMessage: "\(self?.partnerName ?? "")さんをブロックしているため、メッセージを送信できません。")
                    return
                }
                if self?.canSendMessage == 2 {
                    self?.alertUserError(alertMessage: "\(self?.partnerName ?? "")さんにブロックされているため、メッセージを送信できません。")
                    return
                }
            }
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = false
            self?.present(picker, animated: true)
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 60, animated: false)
        messageInputBar.setStackViewItems([button1, button2], forStack: .left, animated: false)
    }
    
    
    // 一つのmessageにつくid (時間あり)
    private func createMessageId() -> String? {
        // date, otherUserEmail, senderEmail
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeMyEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(partnerSafeEmail)_\(safeMyEmail)_\(dateString)"
        
        return newIdentifier
    }
    
    
    
    private func startListenMessage(id: String) {
        DatabaseManager.shared.getAllMessagesForConversation(with: id) { [weak self](result) in
            switch result {
            case .success(let messages_array):
                guard let strongSelf = self else {
                    return
                }
                strongSelf.messages = messages_array
                DispatchQueue.main.async {
                    strongSelf.messagesCollectionView.reloadDataAndKeepOffset()
                    strongSelf.messagesCollectionView.scrollToBottom()
                }
                let lastCount = messages_array.count - 1
                DatabaseManager.shared.iReadConversation(conversationId: strongSelf.conversationId ?? "")
                
                if messages_array[lastCount].sender.senderId == strongSelf.partnerSafeEmail {
                    //ChatVCの既読をつける
                    DatabaseManager.shared.iReadMessage(conversationId: strongSelf.conversationId ?? "", partnerEmail: strongSelf.partnerSafeEmail, date: messages_array[lastCount].sentDate)
                    
//                    guard lastCount != 0 else {
//                        return
//                    }
//                    var i = lastCount
//                    var countOtherMessage = 0
//                    while i >= 0 {
//                        if messages_array[i].sender.senderId == strongSelf.partnerSafeEmail {
//                            countOtherMessage += 1
//                            i -= 1
//                            continue
//                        }
//                        break
//                    }
//                    i = 1
//                    while i <= countOtherMessage {
//                        DatabaseManager.shared.iReadMessage(conversationId: strongSelf.conversationId ?? "", partnerEmail: strongSelf.partnerSafeEmail, date: messages_array[lastCount - i].sentDate)
//                        i += 1
//                    }
                }
            case .failure(let err):
                print("Error (ChatVC startListenMessage): \(err)")
            }
        }
    }
    
    @objc private func dismissSelf() {
        navigationController?.popViewController(animated: true)
    }
    
    private func checkBlock() {
        if let blockedArray = UserDefaults.standard.value(forKey: "blocked") as? [String] {
            for cell in blockedArray {
                if partnerSafeEmail == cell {
                    canSendMessage = 1
                    return
                }
            }
        }
        if let blockedArray = UserDefaults.standard.value(forKey: "amIBlocked") as? [String] {
            for cell in blockedArray {
                if partnerSafeEmail == cell {
                    alertUserError(alertMessage: "\(partnerName)さんにブロックされています")
                    canSendMessage = 2
                    return
                }
            }
        }
    }
    
    private func alertUserError(alertMessage: String) {
        let alert = UIAlertController(title: "メッセージ",
                                      message: alertMessage,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .cancel,
                                      handler: nil))
        present(alert, animated: true)
    }
    
    
}
    



extension ChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
            let selfSender = selfSender,
            let messageId = createMessageId() else {
                return
        }
        messageInputBar.inputTextView.text = nil
        
        if canSendMessage != 0 {
            if canSendMessage == 1 {
                alertUserError(alertMessage: "\(partnerName)さんをブロックしているため、メッセージを送信できません。")
                return
            }
            if canSendMessage == 2 {
                alertUserError(alertMessage: "\(partnerName)さんにブロックされているため、メッセージを送信できません。")
                return
            }
        }
        
        
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToBottom()
        
        // conversation Nodeを作る
        let messageFromInputBar = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          isRead: false,
                                          kind: .text(text))
        
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let mySafeEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let conversationIdNew = "\(partnerSafeEmail)_\(mySafeEmail)"
        // LineとかはChatRoomを作る時点で"\(mySafeEmail)_\(partnerSafeEmail)"のconversaionIdがないか確認している
        // だからメッセージを送っていないのに、conversationVCのConversationsに記録せれ、表示される
        let conversationIdTrue = "\(mySafeEmail)_\(partnerSafeEmail)"
        
        
        if isNewConversation {
            // chatRoomが２個できないように、"\(mySafeEmail)_\(partnerSafeEmail)" のconversaionIdがないか確認
            DatabaseManager.shared.checkTowConversation(with: conversationIdTrue, partnerEmail: partnerSafeEmail) { [weak self](exists) in
                if exists {
                    self?.notNewConversation(conversationId1: conversationIdTrue, messageFromInputBar: messageFromInputBar)
                }
                else {
                    //本当にnewConversation
                    self?.NewConversation(conversationId: conversationIdNew, messageFromInputBar: messageFromInputBar)
                }
            }
        }
        else {
            //append to exsting conversation data
            guard let conversationId = conversationId else {
                return
            }
            DatabaseManager.shared.sendMessage(to: conversationId, safePartnerEmail: partnerSafeEmail, recievedName: partnerName, newMessage: messageFromInputBar) { success in
                if success {
                    print("message sent")
                }
                else {
                    print("fail to sent")
                }
            }
        }
    
    }
    
    
    private func NewConversation(conversationId: String, messageFromInputBar: Message) {
        
        
        DatabaseManager.shared.createNewConversation(with: partnerSafeEmail, partnerName: partnerName, firstMessage: messageFromInputBar, conversationId: conversationId, completion: { [weak self]success in
            if success {
                print("message send")
                self?.isNewConversation = false
                self?.conversationId = conversationId
                self?.startListenMessage(id: conversationId)
            }
            else {
                print("failed to send message")
            }
        })
    }
    
    // お互いが同時にsearchVCでchatRoomを作った場合
    private func notNewConversation(conversationId1: String, messageFromInputBar: Message) {

        DatabaseManager.shared.sendMessage(to: conversationId1, safePartnerEmail: partnerSafeEmail, recievedName: partnerName, newMessage: messageFromInputBar) { [weak self]success in
            if success {
                self?.isNewConversation = false
                self?.conversationId = conversationId1
                self?.startListenMessage(id: conversationId1)
                self?.goAnotherChat(conversationId2: conversationId1)
            }
            else {
                print("failed to send message")
            }
        }
    }
    
    private func goAnotherChat(conversationId2: String) {
        let ChatVC = ChatViewController(partnerEmail: partnerSafeEmail, partnerName: partnerName, conversationId: conversationId2)
        ChatVC.title = partnerName
        navigationController?.pushViewController(ChatVC, animated: true)
    }
    
}


extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    func currentSender() -> SenderType {
        if let selfSender = selfSender {
            // この関数の返り値で自分のmessageかを判断して、右側に緑色で表示される
            return selfSender
        }
        fatalError("selfSender = nil, Userdefaultsでemailを設定しよう")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        switch message.kind {
        case .photo(let media):
            guard let url = media.url else {
                return
            }
            imageView.sd_setImage(with: url, completed: nil)
        default:
            return
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            // my message avatar
        }
        // partnerPhotoUrlにデータが入らないと、繰り返しgetDeonloadUrlをしてしまう
        else {
            if let partnerPhotoURL = self.partnerPhotoUrl {
                avatarView.sd_setImage(with: partnerPhotoURL, completed: nil)
            }
            else {
                // fetch partner Photo URL from batabase
                let path = "profile_picture/\(partnerSafeEmail)-profile.png"
                StorageManager.shared.getDownloadURL(for: path) { [weak self](result) in
                    switch result {
                    case .success(let url):
                        self?.partnerPhotoUrl = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                    case .failure(_):
                        avatarView.image = UIImage(systemName: "person.circle")
                        avatarView.tintColor = .gray
                    }
                }
            }
        }
    }
    
    // メッセージの上に文字を表示
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section == 0 {
            return NSAttributedString(
                string: dateFormatterForChat.string(from: message.sentDate), //MessageKitDateFormatter.shared.string(from: message.sentDate)
                attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16),
                             NSAttributedString.Key.foregroundColor: UIColor.darkGray]
            )
        }
        guard let dateString = setMessageDate(targetMessage: messages[indexPath.section].sentDate, priviousMessage: messages[indexPath.section - 1].sentDate) else {
            return nil
        }
        return NSAttributedString(
            string: dateString, //MessageKitDateFormatter.shared.string(from: message.sentDate)
            attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16),
                         NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        )
    }
    // ラベルの高さを設定（デフォルト0なので必須）
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if indexPath.section == 0 {
            return 40
        }
        guard let _ = setMessageDate(targetMessage: messages[indexPath.section].sentDate, priviousMessage: messages[indexPath.section - 1].sentDate) else {
            return 0
        }
        return 40
    }
    private func setMessageDate(targetMessage: Date, priviousMessage: Date) -> String? {
        let targetString = dateFormatterForChat.string(from: targetMessage)
        let priviousString = dateFormatterForChat.string(from: priviousMessage)
        if targetString == priviousString {
            return nil
        } else {
            return targetString
        }
    }
    
    
    // cellの下に情報を入れる
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if partnerSafeEmail == message.sender.senderId {
            let dateString = dateFormatterForChatCell.string(from: message.sentDate)
            return NSAttributedString(
                string: dateString,
                attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12),
                             NSAttributedString.Key.foregroundColor: UIColor.lightGray]
            )
        }
        else {
            let dateString = dateFormatterForChatCell.string(from: message.sentDate)
            if message.isRead == true {
                return NSAttributedString(
                    string: "\(dateString) 既読",
                    attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12),
                                 NSAttributedString.Key.foregroundColor: UIColor.lightGray]
                )
            }
            else {
                return NSAttributedString(
                    string: dateString,
                    attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12),
                                 NSAttributedString.Key.foregroundColor: UIColor.lightGray]
                )
            }
        }
    }
    // ラベルの高さ
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if indexPath.section == messages.count - 1 {
            return 12
        }
        else if indexPath.section == 0 {
            if messages.count > 1 {
                if "nil" == setMessageInfo(targetMessage: messages[indexPath.section + 1].sentDate, priviousMessage: messages[indexPath.section].sentDate){
                    return 0
                }
                return 12
            }
            else {
                return 12
            }
        }
        else if message.sender.senderId != messages[indexPath.section + 1].sender.senderId {
            return 12
        }
        if "nil" == setMessageInfo(targetMessage: messages[indexPath.section + 1].sentDate, priviousMessage: messages[indexPath.section].sentDate){
            return 0
        }
        return 12
    }
    private func setMessageInfo(targetMessage: Date, priviousMessage: Date) -> String {
        if let elapsedMinute = Calendar.current.dateComponents([.minute], from: priviousMessage, to: targetMessage).minute {
            if elapsedMinute == 0 || elapsedMinute == 1 || elapsedMinute == 2 {
                return "nil"
            }
            else {
                let dateString = dateFormatterForChatCell.string(from: targetMessage)
                return dateString
            }
        }
        return "nil"
    }
    
    
    //message cellに尻尾をつける
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }
    
}


// camera&Libaryのdelegate
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        
        if isNewConversation {
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                return
            }
            picker.dismiss(animated: false, completion: nil)
            
            let mySafeEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
            let conversationIdNew = "\(partnerSafeEmail)_\(mySafeEmail)"
            let conversationIdTrue = "\(mySafeEmail)_\(partnerSafeEmail)"
            
            // chatRoomが２個できないように、"\(mySafeEmail)_\(partnerSafeEmail)"
            // のconversaionIdがないか確認
            DatabaseManager.shared.checkTowConversation(with: conversationIdTrue, partnerEmail: partnerSafeEmail) { [weak self](exists) in
                if exists {
                    self?.isNewConversation = false
                    self?.photoMessage(info: info, conversationId1: conversationIdTrue)
                    
                    let ChatVC = ChatViewController(partnerEmail: self?.partnerSafeEmail ?? "", partnerName: self?.partnerName ?? "", conversationId: conversationIdTrue)
                    ChatVC.title = self?.partnerName ?? ""
                    
                    self?.navigationController?.pushViewController(ChatVC, animated: true)
                }
                else {
                    //本当にnewConversation
                    self?.photoMessage(info: info, conversationId1: conversationIdNew)
                }
            }
        }
        else {
            if let conversationId2 = conversationId {
                picker.dismiss(animated: false, completion: nil)
                photoMessage(info: info, conversationId1: conversationId2)
            }
        }
        
        
//        if let videoUrl = info[.mediaURL] as? URL {
//            // videoのデータ
//            let fileName = "video_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mp4"
//            print(fileName)
//            StorageManager.shared.uploadMessageVideo1(with: videoUrl, fileName: fileName, completion: { [weak self] result in
//                guard let strongSelf = self else {
//                    return
//
//                }
//                switch result {
//                case .success(let urlString):
//                    print("Upload message video: \(urlString)")
//
//                    guard let url = URL(string: urlString),
//                        let placeholder = UIImage(systemName: "plus") else {
//                            return
//                    }
//                    let media = Media(url: url,
//                                      image: nil,
//                                      placeholderImage: placeholder,
//                                      size: .zero)
//                    let message = Message(sender: selfSender,
//                                          messageId: messageId,
//                                          sentDate: Date(),
//                                          kind: .video(media))
//
//                    DatabaseManager.shared.sendMessage(to: conversationId, safePartnerEmail: strongSelf.partnerSafeEmail, recievedName: partnerName, newMessage: message, completion: { success in
//
//                        if success {
//                            print("send video message")
//                        }
//                        else {
//                            print("fail to send video message")
//                        }
//                    })
//
//                case .failure(let err):
//                    print("message video upload error: \(err)")
//                }
//            })
//        }
        
    }
    
    private func photoMessage(info: [UIImagePickerController.InfoKey : Any], conversationId1: String) {
        guard let messageId = createMessageId(),
            let partnerName1 = title else {
            return
        }
        messageIdForImage = messageId
        partnerNameForImage = partnerName1
        conversationIdforImage = conversationId1
    
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            let cropViewController = CropViewController(image: selectedImage)
            cropViewController.delegate = self
            present(cropViewController, animated: true, completion: nil)
        }

    }
    
    private func AnotherIdByPhoto(conversationId: String, messageFromPhoto: Message) {
        DatabaseManager.shared.createNewConversation(with: partnerSafeEmail, partnerName: partnerName, firstMessage: messageFromPhoto, conversationId: conversationId, completion: { [weak self]success in
            if success {
                print("message send")
                self?.isNewConversation = false
                self?.conversationId = conversationId
                self?.startListenMessage(id: conversationId)
                self?.messagesCollectionView.scrollToBottom()
            }
            else {
                print("failed to send message")
            }
        })
    }
    

}

// cellをdidiselectedすると写真やビデオに移る
extension ChatViewController: MessageCellDelegate {
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        switch message.kind {
        case .photo(let photoItem):
            guard let url = photoItem.url else {
                return
            }
            
            let PhotoVC = PhotoViewController(data: nil, url: url)
            let nav = UINavigationController(rootViewController: PhotoVC)
            present(nav, animated: true, completion: nil)
        default:
            break
        }
    }
    
    //アバタータップ
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        let friendVC = FriendProfileViewController(partnerEmail: partnerSafeEmail)
        let nav = UINavigationController(rootViewController: friendVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
    }
    
    //urlをチェックする
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
            
        }
        let message = messages[indexPath.section]
        switch message.kind {
        case .text(let text):
            guard let url = URL(string: text) else {
                return
            }
            if UIApplication.shared.canOpenURL(url) {
                let storyboard = UIStoryboard(name: "Web", bundle: nil)
                let post = storyboard.instantiateViewController(withIdentifier: "segueWeb") as! WebViewController
                post.urlString = url.absoluteString

                let nav = UINavigationController(rootViewController: post)
                nav.modalPresentationStyle = .fullScreen
                present(nav, animated: true)
            }else {
                //not an url
            }
            
        default:
            break
        }
        
    }
    
}


extension ChatViewController: CropViewControllerDelegate {

    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        //加工した画像が取得できる
        
        cropViewController.dismiss(animated: false, completion: nil)
        
        guard partnerNameForImage != "",
              messageIdForImage != "",
              conversationIdforImage != "",
              let selfSender = selfSender else {
            return
        }
        
        // ※画像のデータサイズをKBで表示。
        let imageData:Int = NSData(data: image.pngData()!).count
        let dataToKB = Double(imageData) / 1000.0
        
        //バリデーションを実装
        var data: Data?
        if dataToKB <= 300.0 {
            data = image.pngData()
        }
        else {
            var resizedImage: UIImage?
            if (dataToKB >= 300.0) && (600.0 > dataToKB) {
                resizedImage = image.resized(withPercentage: 0.9)
            }
            else if (dataToKB >= 600.0) && (1200.0 > dataToKB) {
                resizedImage = image.resized(withPercentage: 0.8)
            }
            else if (dataToKB >= 1200.0) && (2400.0 > dataToKB) {
                resizedImage = image.resized(withPercentage: 0.7)
            }
            else if (dataToKB >= 2400.0) && (4800.0 > dataToKB) {
                resizedImage = image.resized(withPercentage: 0.6)
            }
            else if (dataToKB >= 4800.0) && (10000.0 > dataToKB) {
                resizedImage = image.resized(withPercentage: 0.5)
            }
            else if (dataToKB >= 10000.0) && (20000.0 > dataToKB) {
                resizedImage = image.resized(withPercentage: 0.4)
            }
            else if (dataToKB >= 20000.0) && (40000.0 > dataToKB) {
                resizedImage = image.resized(withPercentage: 0.35)
            }
            else if (dataToKB >= 40000.0) && (80000.0 > dataToKB) {
                resizedImage = image.resized(withPercentage: 0.3)
            }
            else {
                resizedImage = image.resized(withPercentage: 0.2)
            }
            
            var resizeData: Int = NSData(data: (resizedImage?.pngData())!).count / 1000
            
            if resizeData > 250 { // 300KB以下にしたい
                data = resizedImage?.jpegData(compressionQuality: 0.8)
                if NSData(data: data!).count/1000 > 300 {
                    while NSData(data: data!).count/1000 > 300 {
                        resizedImage = resizedImage?.resized(withPercentage: 0.9)
                        data = resizedImage?.jpegData(compressionQuality: 0.8)
                        resizedImage = UIImage(data: data!)
                    }
                }
            }
            else {
                data = resizedImage?.pngData()
            }
        }
        
        
        let fileName = messageIdForImage.replacingOccurrences(of: " ", with: "-") + ".png"
        StorageManager.shared.uploadMessagePhoto(with: data!, fileName: fileName, partnerSafeEmail: partnerSafeEmail, completion: { [weak self]result in
            guard let strongSelf = self else {
                return
                
            }
            switch result {
            case .success(let urlString):
                print("Upload message photo: \(urlString)")

                guard let url = URL(string: urlString),
                    let placeholder = UIImage(systemName: "plus") else {
                        return
                }
                let media = Media(url: url,
                                  image: nil,
                                  placeholderImage: placeholder,
                                  size: .zero)
                let message = Message(sender: selfSender,
                                      messageId: self?.messageIdForImage ?? "",
                                      sentDate: Date(),
                                      isRead: false,
                                      kind: .photo(media))
                
                if self?.isNewConversation == true {
                    guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                        return
                    }
                    let mySafeEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
                    let conversationIdNew1 = "\(self?.partnerSafeEmail ?? "")_\(mySafeEmail)"
                    let conversationIdTrue1 = "\(mySafeEmail)_\(self?.partnerSafeEmail ?? "")"
                    
                    DatabaseManager.shared.checkTowConversation(with: conversationIdTrue1, partnerEmail: self?.partnerSafeEmail ?? "") { [weak self](exists) in
                        if exists {
                            self?.AnotherIdByPhoto(conversationId: conversationIdTrue1, messageFromPhoto: message)
                        }
                        else {
                            //本当にnewConversation
                            self?.AnotherIdByPhoto(conversationId: conversationIdNew1, messageFromPhoto: message)
                        }
                    }
                }
                else {
                    DatabaseManager.shared.sendMessage(to: strongSelf.conversationIdforImage, safePartnerEmail: strongSelf.partnerSafeEmail, recievedName: strongSelf.partnerNameForImage, newMessage: message, completion: { [weak self]success in
                        
                        if success {
                            print("send photo message")
                            self?.messagesCollectionView.scrollToBottom()
                        }
                        else {
                            print("fail to send photo message")
                        }
                    })
                }
                
            case .failure(let err):
                print("message photo upload error: \(err)")
            }
        })
        
        
    }

    func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
        // キャンセル時
        cropViewController.dismiss(animated: true, completion: nil)
    }
}
