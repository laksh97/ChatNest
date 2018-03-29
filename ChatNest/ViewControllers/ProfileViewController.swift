import UIKit
import Firebase
import SDWebImage
import Photos
import Toast_Swift

class ProfileViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    @IBOutlet weak var profileView: UIView!
    @IBOutlet weak var profilePic: RoundedImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    
    let storageRef = Storage.storage().reference(forURL: "gs://chatnest-b5001.appspot.com")
    let databaseRef = Database.database().reference(fromURL: "https://chatnest-b5001.firebaseio.com/")
    
    //choosing image
    @IBAction func selectPic(_ sender: Any) {
        
        let picker = UIImagePickerController()
        //create instance of Image picker controller
        _ = UIImagePickerController()
        //set delegate
        picker.delegate = self
        //set details
        //is the picture going to be editable(zoom)?
        picker.allowsEditing = false
        //what is the source type
        picker.sourceType = .photoLibrary
        //set the media type
        picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
        //show photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
    //when the user selects a photo
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        //create holder variable for chosen image
        var chosenImage = UIImage()
        //save image into variable
        print(info)
        chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        //update image view
        profilePic.image = chosenImage
        //dismiss
        dismiss(animated: true, completion: nil)
    }
    
    //when the user hits cancel
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func back(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func logOut(_ sender: Any) {
        
        UserManager.logOutUser { (status) in
            if status == true {
                print("LOGGED OUT")
                self.performSegue(withIdentifier: "unwindSegueToLogin", sender: self)
                
            }
        }
    }
    
    @IBAction func update(_ sender: Any) {
        
        updateUsersProfile()
    }
    
    //loading profile data of the current user
    func loadProfileData(){
        //if the user is logged in get the profile data
        if let userID = Auth.auth().currentUser?.uid{
            databaseRef.child("users").child(userID).child("credentials").observe(.value, with: { (snapshot) in
                
                //create a dictionary of users profile data
                let values = snapshot.value as? NSDictionary
                
                //if there is a url image stored in photo
                if let profileImageURL = values?["profilePicLink"] as? String{
                    //using sd_setImage load photo
                    self.profilePic.sd_setImage(with: URL(string: profileImageURL), placeholderImage: UIImage(named: " "))
                }
                
                self.nameTextField.text = values?["name"] as? String
                
            })
            
        }
    }
    
    //updating the data of the user in the database
    func updateUsersProfile() {
        //check to see if the user is logged in
        guard
            let userID = Auth.auth().currentUser?.uid,
            let newUserName  = self.nameTextField.text,
            let image = profilePic.image,
            let newImage = UIImageJPEGRepresentation(image,0.1) else {
                return
        }
        
        //upload to firebase storage
        let storageItem = storageRef.child("usersProfilePics").child(userID)
        storageItem.putData(newImage, metadata: nil) { (metadata, error) in
            
            if let error = error {
                print(error)
                return
            }
            if let profilePhotoURL = metadata?.downloadURL()?.absoluteString{
                let newValuesForProfile =
                    ["profilePicLink": profilePhotoURL,
                     "name": newUserName]
                
                //update the firebase database for that user
                self.databaseRef.child("users").child(userID).child("credentials").updateChildValues(newValuesForProfile, withCompletionBlock: { (error, ref) in
                    if let error = error {
                        print(error)
                        return
                    }
                    print("Profile Updated Successfully")
                    
                })
                
            }
        }
    }
    
    //textfield delegates
    func textFieldDidBeginEditing(_ textField: UITextField) {
        return
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(profileView)
        loadProfileData()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
