import CoreLocation

class Message {
    var mId: String
    var text: String
    var timestamp: Double
    var dateString: String
    var senderName: String
    var senderId: String
    var latitude: Double
    var longitude: Double
    
    init(mId: String, text: String, timestamp: Double, dateString: String, senderName: String, senderId: String, latitude: Double, longitude: Double) {
        self.mId = mId
        self.text = text
        self.timestamp = timestamp
        self.dateString = dateString
        self.senderName = senderName
        self.senderId = senderId
        self.latitude = latitude
        self.longitude = longitude
    }
}
