//
//  AuthViewController.swift
//  BiometricLocalAuth
//
//  Created by Eugene Lezov on 07.06.2018.
//  Copyright © 2018 Eugene Lezov. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa
import NotificationBannerSwift
import LocalAuthentication

class AuthViewController: UIViewController {

    // MARK: - Private
    
    private var alertHelper: AlertHelper!
    private var biometricAuthHelper: BiometricAuthHelper!
    
    
    // MARK: - Outlets
    
    @IBOutlet weak var biometricAuthButton: UIButton!
    
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        alertHelper = AlertHelper(presenter: self)
        biometricAuthHelper = BiometricAuthHelper()
        configureBiometricAuthButton()
    }
    
    
    // MARK: - Private methods
    
    private func configureBiometricAuthButton() {
        
        biometricAuthButton.rx.tap
            .asObservable()
            .bind { [weak self] in
                self?.biometricAuthHelper.authenticationWithBiometric(reply: { [weak self] (success, error) in
                    guard let `self` = self else { return }
                    
                    if let error = error {
    
                        self.handleError(error: error)
                    } else {
                        // Отслеживаем изменение биометрических данных
                        self.handleChangeBiometricDate()
        
                        DispatchQueue.main.async {
                            self.configureBiometricAuthButton(image: #imageLiteral(resourceName: "fingerprint_success"), isEnabled: false)
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2, execute: {
                            self.setRootAsSuccess()
                        })
                    }
                })
            }
    }
    
    private func configureBiometricAuthButton(image: UIImage, isEnabled: Bool) {
        self.biometricAuthButton.setImage(image, for: UIControlState())
        self.biometricAuthButton.isEnabled = isEnabled
    }
    
    func setRootAsSuccess() {
       WindowBuilder.setVCasRoot(vc: SuccessViewController.self)
    }
    
    private func showErrorNotification(title: String, subtitle: String, style: BannerStyle = .danger) {
        DispatchQueue.main.async {
            let banner = NotificationBanner(title: title, subtitle: subtitle, style: style)
            banner.duration = 3.0
            banner.show()
        }
    }
    
    private func handleError(error: Error) {
        let messageError = biometricAuthHelper.evaluateAuthenticationPolicyMessageForLA(errorCode: error._code)
        let errorCode = error._code
        if #available(iOS 11.0, *) {
            if [LAError.biometryLockout.rawValue,
                LAError.biometryNotAvailable.rawValue,
                LAError.biometryNotEnrolled.rawValue].contains(where: { $0 == errorCode }) {
                    self.alertHelper.showAlertToDeviceSettings(errorMessage: messageError)
            } else {
                self.showErrorNotification(title: "Auth Failed", subtitle: messageError)
            }
        } else {
            if [LAError.touchIDLockout.rawValue,
                LAError.touchIDNotAvailable.rawValue,
                LAError.touchIDNotEnrolled.rawValue].contains(where: { $0 == errorCode }) {
                    self.alertHelper.showAlertToDeviceSettings(errorMessage: messageError)
            } else {
                self.showErrorNotification(title: "Auth Failed", subtitle: messageError)
            }
        }
        
        DispatchQueue.main.async {
            self.configureBiometricAuthButton(image: #imageLiteral(resourceName: "fingerprint_wrong"), isEnabled: false)
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2, execute: {
            self.configureBiometricAuthButton(image: #imageLiteral(resourceName: "finger"), isEnabled: true)
        })
    }
    
    private func handleChangeBiometricDate() {
        // Проверка на изменение данных
        if !self.biometricAuthHelper.biometricDateIsValid() {
            self.showErrorNotification(title: "You biometric data was changed", subtitle: "Be carefull", style: .warning)
        }
    }
}

