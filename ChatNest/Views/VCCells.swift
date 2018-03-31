import Foundation
import UIKit
import QuartzCore

class VCCells: UITableViewCell{
    
}

class SenderCell: UITableViewCell {
    @IBOutlet weak var senderMsgLabel: UILabel!
    @IBOutlet private weak var senderNameLabel: UILabel!
    @IBOutlet weak var senderView: UIView!
    @IBOutlet private weak var timeLabel: UILabel!
    
    func clearCellData()  {
        self.senderMsgLabel.text = nil
    }
    
    func updateMessage(message: Message) {
        self.senderMsgLabel.text = message.text
        senderNameLabel.text = message.senderName
        timeLabel.text = message.dateString
        
        // To get rounded view for sender message bubble
        senderView.layer.cornerRadius = 8
    }
}

class ReceiverCell: UITableViewCell {
    @IBOutlet weak var receiverMsgLabel: UILabel!
    @IBOutlet weak var receiverNameLabel: UILabel!
    @IBOutlet weak var receiverView: UIView!
    @IBOutlet weak var rtimeLabel: UILabel!
    
    func clearCellData()  {
        self.receiverMsgLabel.text = nil
    }
    
    func updateMessage(message: Message) {
        self.receiverMsgLabel.text = message.text
        receiverNameLabel.text = message.senderName
        rtimeLabel.text = message.dateString
        
        // To get rounded view for receiver message bubble
        receiverView.layer.cornerRadius = 8
    }
}

