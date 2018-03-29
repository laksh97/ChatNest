import UIKit
import Firebase
import CoreLocation

class ConversationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var inputBar: UIView!
    @IBOutlet weak var msgTextView: UITextView!
    @IBOutlet weak var totalChatView: UIView!
   
    var currentUser: User?
    var room: Room? {
        didSet {
            let roomsRef: DatabaseReference = Database.database().reference().child("rooms")
            let roomRef = roomsRef.child(room!.id)
            messageRef = roomRef.child("messages")
            observeMessages()
            
            if room?.locAware == true {
                // To create a view in navigation bar
                let navView = UIView()
                
                // Create the label for room name
                let label = UILabel()
                label.text = room?.roomName
                label.sizeToFit()
                label.center = navView.center
                label.textAlignment = NSTextAlignment.center
                
                // Create the image view to indicate location aware room
                let imageView = UIImageView()
                imageView.image = UIImage(named: "Checkmarkempty2")
                
                // To maintain the image's aspect ratio
                let imageAspect = imageView.image!.size.width/imageView.image!.size.height
                
                // Setting the image frame so that it's immediately before the text
                imageView.frame = CGRect(x: label.frame.origin.x-label.frame.size.height*imageAspect/1.25, y: label.frame.origin.y/2, width: (label.frame.size.height*imageAspect)/2.5, height: (label.frame.size.height)/2)
                imageView.contentMode = UIViewContentMode.scaleAspectFit
                
                // Add both the label and image view to the navView
                navView.addSubview(label)
                navView.addSubview(imageView)
                
                // Set the navigation bar's navigation item's titleView to the navView
                self.navigationItem.titleView = navView
                
                // Set the navView's frame to fit within the titleView
                navView.sizeToFit()
            }
            else
            {
                // To create a view in navigation bar
                let navView = UIView()
                
                // Create the label
                let label = UILabel()
                label.text = room?.roomName
                label.sizeToFit()
                label.center = navView.center
                label.textAlignment = NSTextAlignment.center
                
                // Add the label to the navView
                navView.addSubview(label)
                
                // Set the navigation bar's navigation item's titleView to the navView
                self.navigationItem.titleView = navView
                
                // Set the navView's frame to fit within the titleView
                navView.sizeToFit()
                
            }
        }
    }
    
    let databaseRef = Database.database().reference(fromURL: "https://chatnest-b5001.firebaseio.com/")
    
    // Setting the radius to 1000 metres
    private let radius: CLLocationDistance = 1000
    
    private var messages : [Message] = []
    private var messageRef: DatabaseReference?
    private var messagesRefHandle: DatabaseHandle?
   
    // To create a button for map
    lazy var rightButton: UIBarButtonItem  = {
        let image = UIImage.init(named: "map")?.withRenderingMode(.alwaysOriginal)
        let button  = UIBarButtonItem.init(image: image, style: .plain, target: self, action: #selector(ConversationViewController.showMap))
        return button
    }()
    
    // Segue to map view controller
    @objc func showMap() {
        self.performSegue(withIdentifier: "goToMap", sender: self)
    }
    
    override var canBecomeFirstResponder: Bool{
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Keyboard handling
        NotificationCenter.default.addObserver(self, selector: #selector(ConversationViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ConversationViewController.showKeyboard(notification:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ConversationViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ConversationViewController.keyboardHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //To eliminate the separators of the UITableView
        self.chatTableView.separatorStyle = UITableViewCellSeparatorStyle.none
        self.chatTableView.delegate = self
        self.chatTableView.dataSource = self
        
        // To assign an image to map button
        self.navigationItem.rightBarButtonItem = self.rightButton
        let image = #imageLiteral(resourceName: "map")
        let contentSize = CGSize.init(width: 30, height: 30)
        UIGraphicsBeginImageContextWithOptions(contentSize, false, 0.0)
        let _  = UIBezierPath.init(roundedRect: CGRect.init(origin: CGPoint.zero, size: contentSize), cornerRadius: 14).addClip()
        image.draw(in: CGRect(origin: CGPoint.zero, size: contentSize))
        let path = UIBezierPath.init(roundedRect: CGRect.init(origin: CGPoint.zero, size: contentSize), cornerRadius: 14)
        path.lineWidth = 2
        UIColor.white.setStroke()
        path.stroke()
        let finalImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!.withRenderingMode(.alwaysOriginal)
        UIGraphicsEndImageContext()
        rightButton.image = finalImage
        
        // To self size the cells
        self.chatTableView.estimatedRowHeight = 68.0
        chatTableView.rowHeight = UITableViewAutomaticDimension
        
        NSLog("Finished loading")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        msgTextView.resignFirstResponder()
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        NSLog("prepare \(String(describing: segue.identifier))")
        
        if segue.identifier == "goToMap" {
            guard let mapVC = segue.destination as? MapViewController else {
                return
            }
            
            let newestMessage = self.latestMessages()
            mapVC.messages = newestMessage
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sid = Auth.auth().currentUser?.uid
        let message = messages[indexPath.row]
        let messageSenderId = message.senderId
        
        // Comparing sender id with currently logged in user id
        if sid == messageSenderId {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Sender", for: indexPath) as! SenderCell
            let message = messages[indexPath.row]
            cell.updateMessage(message: message)
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Receiver", for: indexPath) as! ReceiverCell
            let message = messages[indexPath.row]
            cell.updateMessage(message: message)
            return cell
        }
    }
  
    // Animating the cells in table view
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView.isDragging {
            cell.transform = CGAffineTransform.init(scaleX: 0.5, y: 0.5)
            UIView.animate(withDuration: 0.3, animations: {
                cell.transform = CGAffineTransform.identity
            })
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        msgTextView.resignFirstResponder()
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.msgTextView.resignFirstResponder()
    }
    
    func latestMessages() -> [Message] {
        // Store the messages in an array of type Message
        var newestMessagesByUser : [String: Message] = [:]
       
        // To obtain the unique user ids in the chatroom
        let currentUserId = Auth.auth().currentUser?.uid
        
        messages.filter { message in
            return message.senderId != currentUserId
            }.forEach { message in
                
                let userId = message.senderId
                if let currentMessage = newestMessagesByUser[userId] {
                    
                    // Sorting the messages based on timestamp
                    if currentMessage.timestamp < message.timestamp {
                        newestMessagesByUser[userId] = message
                    }
                } else {
                    newestMessagesByUser[userId] = message
                }
        }
        
        let newestMessages = newestMessagesByUser.values
        newestMessages.forEach {
            NSLog("Message: \($0)")
        }
        return Array(newestMessages)
    }
   
    // To convert the timestamp into a date
    func timeSince(from: Date, numericDates: Bool = false) -> String {
        let calendar = Calendar.current
        let now = NSDate()
        let earliest = now.earlierDate(from as Date)
        let latest = earliest == now as Date ? from : now as Date
        let components = calendar.dateComponents([.year, .weekOfYear, .month, .day, .hour, .minute, .second], from: earliest, to: latest as Date)
        
        var result = ""
        
        if components.year! >= 2 {
            result = "\(components.year!) years ago"
        } else if components.year! >= 1 {
            if numericDates {
                result = "1 year ago"
            } else {
                result = "Last year"
            }
        } else if components.month! >= 2 {
            result = "\(components.month!) months ago"
        } else if components.month! >= 1 {
            if numericDates {
                result = "1 month ago"
            } else {
                result = "Last month"
            }
        } else if components.weekOfYear! >= 2 {
            result = "\(components.weekOfYear!) weeks ago"
        } else if components.weekOfYear! >= 1 {
            if numericDates {
                result = "1 week ago"
            } else {
                result = "Last week"
            }
        } else if components.day! >= 2 {
            result = "\(components.day!) days ago"
        } else if components.day! >= 1 {
            if numericDates {
                result = "1 day ago"
            } else {
                result = "Yesterday"
            }
        } else if components.hour! >= 2 {
            result = "\(components.hour!) hours ago"
        } else if components.hour! >= 1 {
            if numericDates {
                result = "1 hour ago"
            } else {
                result = "An hour ago"
            }
        } else if components.minute! >= 2 {
            result = "\(components.minute!) minutes ago"
        } else if components.minute! >= 1 {
            if numericDates {
                result = "1 minute ago"
            } else {
                result = "A minute ago"
            }
        } else if components.second! >= 3 {
            result = "\(components.second!) seconds ago"
        } else {
            result = "Just now"
        }
        
        return result
    }
    
    // Keyboard handling
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            self.inputBar.frame.origin.y -= keyboardSize.height - view.safeAreaInsets.bottom
        }
        NSLog("before \(inputBar.frame)")
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if ((notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue) != nil {
            self.inputBar.frame.origin.y = 587
        }
    }
    
    @objc func keyboardHide(notification: Notification){
        chatTableView.contentInset = UIEdgeInsets.zero
    }
    
    @objc func showKeyboard(notification: Notification) {
        if let frame = notification.userInfo![UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let height = frame.cgRectValue.height
            self.chatTableView.contentInset.bottom = height
            self.chatTableView.scrollIndicatorInsets.bottom = height
            
            // To scroll to the last message
            if self.messages.count > 0 {
                self.chatTableView.scrollToRow(at: IndexPath.init(row: self.messages.count - 1, section: 0), at: .bottom, animated: true)
            }
        }
    }
    
    // To send a message
    @IBAction func sendMessage(_ sender: Any) {
        NSLog("Message added")
        
        let messages = msgTextView.text
        let newMessageRef = messageRef!.childByAutoId()
        let locVal = LocationManager.shared.userLocation?.coordinate
        
        if let userID = Auth.auth().currentUser?.uid {
            databaseRef.child("users").child(userID).child("credentials").observe(.value, with: { (snapshot) in
                // Create a dictionary of the users' data
                let values = snapshot.value as? NSDictionary
                let senderName = values?["name"] as? String
                let messageItem = [
                    "text" : messages as Any,
                    "timestamp" : ServerValue.timestamp(),
                    "senderName": senderName as Any,
                    "senderId": Auth.auth().currentUser?.uid as Any,
                    "latitude": locVal?.latitude as Any,
                    "longitude": locVal?.longitude as Any
                    ] as [String : Any]
                
                newMessageRef.setValue(messageItem)
                self.msgTextView.text = ""
            }
        )}
    }
    
    private func observeMessages() {
        // We can use the observe method to listen for new messages being written to the Firebase DB
          NSLog("observe messages function entry")
    
        // To update the messages in table view
        func updateTable() {
            chatTableView.insertRows(at: [IndexPath.init(row: self.messages.count - 1, section: 0)], with: .fade)
            chatTableView.scrollToRow(at: IndexPath.init(row: self.messages.count - 1, section: 0), at: .bottom, animated: true)
        }
        
        messagesRefHandle = messageRef!.observe(.childAdded) { (snapshot) -> Void in
            
            guard
                let messageData = snapshot.value as? NSDictionary,
                let text = messageData["text"] as? String,
                let senderName = messageData["senderName"] as? String,
                let timestamp = messageData["timestamp"] as? Double,
                let senderId = messageData["senderId"] as? String,
                let latitude = messageData["latitude"] as? Double,
                let longitude = messageData["longitude"] as? Double,
                text.count > 0 else {
                    print("Error! Couldn't load messages")
                    return
            }
            let id = snapshot.key

            // To convert the timestamp to date
            let date = Date(timeIntervalSince1970: timestamp / 1000)
            let dateString = self.timeSince(from: date, numericDates: true)  // Just now
            
            NSLog("\(dateString)")
            NSLog("\(senderName)")
            NSLog("\(senderId)")
            NSLog("\(text)")
            
            // To create a message
            let message = Message(messageId: id, text: text, timestamp: timestamp, dateString: dateString, senderName: senderName, senderId: senderId, latitude: latitude, longitude: longitude)
            
            let sid = Auth.auth().currentUser?.uid
            
            // To append the message in a location aware chat
            if self.room?.locAware == true {
                guard sid != senderId else {
                    self.messages.append(message)
                    updateTable()
                    return
                }
                
                // To append the message provided there is a location
                guard let userLoc = LocationManager.shared.userLocation else {
                    self.messages.append(message)
                    updateTable()
                    return
                }
                
                NSLog("userLocVal in ConvVC is: \(userLoc)")
                
                let msgLocation = CLLocation(latitude: latitude, longitude: longitude)
                
                // Set distanceInMeters to the distance between the user's current location and the location of the message.
                let distanceInMeters = userLoc.distance(from: msgLocation)
                NSLog("Distance \(distanceInMeters)")
                
                // If distance is less than the radius, append the message
                guard distanceInMeters < self.radius else {
                    return
                }
                self.messages.append(message)
                updateTable()
            }
            else {
                self.messages.append(message)
                updateTable()
            }
        }
    }
}


