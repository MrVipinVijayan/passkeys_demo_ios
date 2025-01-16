/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view where the user can sign in, or create an account.
*/

import AuthenticationServices
import UIKit
import os
import LocalAuthentication

class SignInViewController: UIViewController {
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var authsLabel: UILabel!

    private var signInObserver: NSObjectProtocol?
    private var signInErrorObserver: NSObjectProtocol?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        signInObserver = NotificationCenter.default.addObserver(forName: .UserSignedIn, object: nil, queue: nil) {_ in
            self.didFinishSignIn()
        }

        signInErrorObserver = NotificationCenter.default.addObserver(forName: .ModalSignInSheetCanceled, object: nil, queue: nil) { _ in
            self.showSignInForm()
        }

        guard let window = self.view.window else { fatalError("The view was not in the app's view hierarchy!") }
        (UIApplication.shared.delegate as? AppDelegate)?.accountManager.signInWith(anchor: window, preferImmediatelyAvailableCredentials: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if let signInObserver = signInObserver {
            NotificationCenter.default.removeObserver(signInObserver)
        }

        if let signInErrorObserver = signInErrorObserver {
            NotificationCenter.default.removeObserver(signInErrorObserver)
        }
        
        super.viewDidDisappear(animated)
    }

    @IBAction func createAccount(_ sender: Any) {
        guard let userName = userNameField.text else {
            Logger().log("No user name provided")
            return
        }

        self.view.endEditing(true)
        
        guard let window = self.view.window else { fatalError("The view was not in the app's view hierarchy!") }
        (UIApplication.shared.delegate as? AppDelegate)?.accountManager.signUpWith(userName: userName, anchor: window)
    }
    
    @IBAction func signInToAccount(_ sender: Any) {
        guard userNameField.text != nil else {
            Logger().log("No user name provided")
            return
        }
        
        self.view.endEditing(true)

//        guard let window = self.view.window else { fatalError("The view was not in the app's view hierarchy!") }
//        (UIApplication.shared.delegate as? AppDelegate)?.accountManager.signInWith(anchor: window, preferImmediatelyAvailableCredentials: true)
    }

    func showSignInForm() {
        userNameLabel.isHidden = false
        userNameField.isHidden = false
        passwordLabel.isHidden = false
        passwordField.isHidden = false

        guard let window = self.view.window else { fatalError("The view was not in the app's view hierarchy!") }
        (UIApplication.shared.delegate as? AppDelegate)?.accountManager.beginAutoFillAssistedPasskeySignIn(anchor: window)
    }

    func didFinishSignIn() {
        self.view.window?.rootViewController = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "UserHomeViewController")
    }

    @IBAction func tappedBackground(_ sender: Any) {
        self.view.endEditing(true)
    }
    
    @IBAction func checkPlatformAuthenticators(_ sender: Any) {
        let availableAuthenticators = getAvailableAuthenticators()
        print(availableAuthenticators)
        authsLabel.text = availableAuthenticators
    }
    
    func getAvailableAuthenticators() -> String {
        let context = LAContext()
        var error: NSError?
        var message = "Available Authenticators: "

        // Check if the device supports biometric authentication
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // Determine the type of biometric authentication available
            switch context.biometryType {
            case .faceID:
                message += "Face ID"
            case .touchID:
                message += "Touch ID"
            case .opticID:
                message += "Optic ID" // Add this if Optic ID is supported in future updates
            case .none:
                message += "None"
            @unknown default:
                message += "Unknown Biometric Type"
            }
        } else {
            // Handle the case where biometrics are not available
            if let error = error {
                message += "Biometric authentication is not available (\(error.localizedDescription))"
            } else {
                message += "No biometric authentication available."
            }
        }

        // Add additional authentication methods supported by the device
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            if message.contains("Face ID") || message.contains("Touch ID") || message.contains("Optic ID") {
                message += ", Passcode"
            } else {
                message += "Passcode"
            }
        }

        return message
    }

}

