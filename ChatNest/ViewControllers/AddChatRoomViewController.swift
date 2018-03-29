import UIKit
import QuartzCore
import Firebase

class AddChatRoomViewController: UIViewController {
    
    @IBOutlet weak var input: UITextField!
    @IBOutlet weak var locAwareLabel: UILabel!
    @IBOutlet weak var btnCheckBox: UIButton!
    
    @IBOutlet weak var errorLabel: UILabel!
    private var roomRef: DatabaseReference = Database.database().reference().child("rooms")
    private var roomRefHandle: DatabaseHandle?

    let databaseRef = Database.database().reference(fromURL: "https://chatnest-b5001.firebaseio.com/")
    
    
    var isChecked: Bool = false {
        didSet{
            if isChecked == true {
                 btnCheckBox.setImage(UIImage(named:"Checkmark"), for: .selected)
            } else {
                btnCheckBox.setImage(UIImage(named:"Checkmarkempty2"), for: .normal)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        btnCheckBox.setImage(UIImage(named:"Checkmarkempty2"), for: .normal)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        input.layer.cornerRadius = 10.0
        guard let addRoom = input.text, addRoom != "" else{
            print("Text field is empty")
            return
        }
        
        
    }
    
    @IBAction func addRoom(_ sender: Any) {
        if(input.text!.isEmpty)
        {
            self.errorLabel.isHidden = false
            input.resignFirstResponder()
        }
        else
        {
            //Add chatroom and unwind to tableVC
            performSegue(withIdentifier: "addRoom", sender: self)
        }
        
    }
    @IBAction func checkMarkTapped(_ sender: UIButton) {
        
        if sender == btnCheckBox {
            if isChecked == true {
                isChecked = false
            } else {
                isChecked = true
            }
        }
         //To animate Checkbox
        UIView.animate(withDuration: 0.1, delay: 0.1, options: .curveLinear, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            
        }) { (success) in
            UIView.animate(withDuration: 0.1, delay: 0.1, options: .curveLinear, animations: {
                sender.isSelected = !sender.isSelected
                sender.transform = .identity
            }, completion: nil)
        }
    }
}
