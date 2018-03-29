import UIKit
import Photos
import Toast_Swift

class SignUpViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //MARK: Properties
    
    @IBOutlet weak var registerMainView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet var registerView: UIView!
    @IBOutlet weak var profilePicView: RoundedImageView!
    @IBOutlet weak var registerNameField: UITextField!
    @IBOutlet weak var registerEmailField: UITextField!
    @IBOutlet weak var registerPasswordField: UITextField!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet var inputFields: [UITextField]!
    
    @IBAction func Cancel(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
    let imagePicker = UIImagePickerController()
    var errorFlag = false
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return UIInterfaceOrientationMask.portrait
        }
    }
    
    @IBAction func register(_ sender: Any) {
        inputValidation()
        if(errorFlag != true)
        {
            self.showLoading(state: true)
            UserManager.registerUser(withName: self.registerNameField.text!, email: self.registerEmailField.text!, password: self.registerPasswordField.text!, profilePic: self.profilePicView.image!) { [weak weakSelf = self] (status) in
                DispatchQueue.main.async {
                    //TODO: implementing toast
                    weakSelf?.showLoading(state: false)
                    //
                    if status == true {
                        weakSelf?.profilePicView.image = UIImage.init(named: "profile pic")
                        for item in self.inputFields {
                            item.text = ""
                            self.warningLabel.isHidden = true
                        }
                        self.registerMainView.makeToast("Registered successfully", duration: 2) {didTap in
                            if didTap {
                                print("Completion from tap")
                            } else {
                                self.dismiss(animated: true, completion: nil)
                            }
                        }
                    } else {
                        self.warningLabel.isHidden = false
                        self.warningLabel.text = "That email is already taken. Please try another."
                        self.registerEmailField.becomeFirstResponder()
                    }
                }
            }
        }
    }
    
    //picking up a profile picture
    
    @IBAction func selectPic(_ sender: Any) {
        let sheet = UIAlertController(title: nil, message: "Select the source", preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.openPhotoPickerWith(source: .camera)
        })
        let photoAction = UIAlertAction(title: "Gallery", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.openPhotoPickerWith(source: .library)
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        sheet.addAction(cameraAction)
        sheet.addAction(photoAction)
        sheet.addAction(cancelAction)
        self.present(sheet, animated: true, completion: nil)
    }
    
    //Text Field Delegates
    func textFieldDidBeginEditing(_ textField: UITextField) {
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    //To check if email address is valid
    func isValidEmailAddress(emailAddressString: String) -> Bool {
        var returnValue = true
        let emailRegEx = "[A-Z0-9a-z.-_]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,3}"
        
        do {
            let regex = try NSRegularExpression(pattern: emailRegEx)
            let nsString = emailAddressString as NSString
            let results = regex.matches(in: emailAddressString, range: NSRange(location: 0, length: nsString.length))
            
            if results.count == 0
            {
                returnValue = false
            }
            
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            returnValue = false
        }
        return returnValue
    }
    
    //spinner to show loading
    func showLoading(state: Bool)  {
        if state {
            registerView.alpha = 0.5
            registerView.isUserInteractionEnabled = false
            self.warningLabel.isHidden = true
            self.spinner.startAnimating()
        } else {
            registerView.alpha = 1
            registerView.isUserInteractionEnabled = true
            self.spinner.stopAnimating()
            self.warningLabel.isHidden = true
        }
    }
    
    //InputValidation
    func inputValidation()
    {
        let isEmailValid = isValidEmailAddress(emailAddressString:registerEmailField.text!)
        errorFlag = false
        if(self.registerPasswordField.text!.count < 6)
        {
            errorFlag = true
            self.warningLabel.isHidden = false
            self.warningLabel.text = "Password must atleast be 6 characters long"
            self.registerPasswordField.becomeFirstResponder()
        }
        if(isEmailValid != true)
        {
            errorFlag = true
            self.warningLabel.isHidden = false
            self.warningLabel.text = "Invalid email address"
            self.registerEmailField.becomeFirstResponder()
        }
        if(self.registerNameField.text!.isEmpty)
        {
            errorFlag = true
            self.warningLabel.isHidden = false
            self.warningLabel.text = "Please enter a username"
            self.registerNameField.becomeFirstResponder()
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeObservers()
    }
    
    //add method to handle tap event on the view and dismiss keyboard
    
    @objc func didTapView(gesture: UITapGestureRecognizer)
    {
        self.registerMainView.endEditing(true)
    }
    
    //add observers for UIkeyboard will show and UIkeyboard will hide notification
    func addObservers(){
        NotificationCenter.default.addObserver(forName: .UIKeyboardWillShow, object: nil, queue: nil)
        {
            notification in self.keyboardWillShow(notification: notification)
        }
        NotificationCenter.default.addObserver(forName: .UIKeyboardWillHide, object: nil, queue: nil)
        {
            notification in self.keyboardWillHide(notification: notification)
        }
        
    }
    
    //add method to handle keyboardwillshow
    func keyboardWillShow(notification: Notification)
    {
        guard let userInfo = notification.userInfo,
            let frame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
                return
        }
        let contentInset = UIEdgeInsets(top: 0,left: 0,bottom: frame.height,right:0)
        scrollView.contentInset = contentInset
    }
    
    func keyboardWillHide(notification: Notification)
    {
        scrollView.contentInset = UIEdgeInsets.zero
    }
    
    func removeObservers()
    {
        NotificationCenter.default.removeObserver(self)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.profilePicView.image = pickedImage
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    
    func openPhotoPickerWith(source: PhotoSource) {
        switch source {
        case .camera:
            let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
            if (status == .authorized || status == .notDetermined) {
                self.imagePicker.sourceType = .camera
                self.imagePicker.allowsEditing = true
                self.present(self.imagePicker, animated: true, completion: nil)
            }
        case .library:
            let status = PHPhotoLibrary.authorizationStatus()
            if (status == .authorized || status == .notDetermined) {
                self.imagePicker.sourceType = .savedPhotosAlbum
                self.imagePicker.allowsEditing = true
                self.present(self.imagePicker, animated: true, completion: nil)
            }
        }
    }
    
    //View controller life cycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.registerMainView.addSubview(registerView)
        self.imagePicker.delegate = self
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}


