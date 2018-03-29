import Foundation
import Firebase

class UserManager: NSObject {
    
    //MARK: Methods
    class func registerUser(withName: String, email: String, password: String, profilePic: UIImage, completion: @escaping (Bool) -> Swift.Void) {
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            
            guard error == nil else {
                completion(false)
                return
            }
            
            user?.sendEmailVerification(completion: nil)
            let storageRef = Storage.storage().reference().child("usersProfilePics").child(user!.uid)
            let imageData = UIImageJPEGRepresentation(profilePic, 0.1)
            
            storageRef.putData(imageData!, metadata: nil) { (metadata, err) in
                guard err == nil else {
                    return
                }
                
                let path = metadata?.downloadURL()?.absoluteString
                let values = ["name": withName, "email": email, "profilePicLink": path!]
                Database.database().reference().child("users").child((user?.uid)!).child("credentials").updateChildValues(values) { (errr, _) in
                    guard errr == nil else {
                        return
                    }
                    
                    let userInfo = ["email" : email, "password" : password]
                    UserDefaults.standard.set(userInfo, forKey: "userInformation")
                    completion(true)
                }
            }
        }
    }
    
    class func loginUser(withEmail: String, password: String, completion: @escaping (Bool) -> Swift.Void) {
        Auth.auth().signIn(withEmail: withEmail, password: password, completion: { (user, error) in
            if error == nil {
                let userInfo = ["email": withEmail, "password": password]
                UserDefaults.standard.set(userInfo, forKey: "userInformation")
                completion(true)
            } else {
                completion(false)
            }
        })
    }
    
    class func logOutUser(completion: @escaping (Bool) -> Swift.Void) {
        do {
            try Auth.auth().signOut()
            UserDefaults.standard.removeObject(forKey: "userInformation")
            completion(true)
        } catch _ {
            completion(false)
        }
    }
    
    class func checkUserVerification(completion: @escaping (Bool) -> Swift.Void) {
        Auth.auth().currentUser?.reload(completion: { (_) in
            let status = (Auth.auth().currentUser?.isEmailVerified)!
            completion(status)
        })
    }
}
