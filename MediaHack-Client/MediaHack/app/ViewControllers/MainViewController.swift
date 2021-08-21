//
//  TestVC.swift
//  MediaHack
//
//  Created by Vitalii Stikhurov on 21.08.2021.
//

import UIKit
import SharedCode
import Networking

class MainViewController: UIViewController {
    let receiveTextView = UITextView()
    let playButton = UILabel()
    override func viewDidLoad() {
        super.viewDidLoad()
        playButton.isHidden = true
        setupViews()
    }

    func setupViews() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        view.addSubview(stackView)
        stackView.pinEdgesToSuperView(edges: .init(top: 64, left: 16, bottom: .nan, right: 16))

        let idLabel = UILabel()
        let idField = UITextField()
        view.backgroundColor = UIColor.systemBackground
        idLabel.text = "ID"

        let pinCode = UIView()
        stackView.addArrangedSubview(pinCode)
        pinCode.addSubview(idLabel)
        pinCode.addSubview(idField)

        idLabel.pinEdgesToSuperView(edges: .init(top: 0, left: 0, bottom: .nan, right: 0))
        idField.pin(.top).to(idLabel, .bottom).const(2).equal()
        idField.pinEdgesToSuperView(edges: .init(top: .nan, left: 0, bottom: 0, right: 0))
        idField.pin(.height).const(32).equal()
        idField.backgroundColor = .secondarySystemBackground
        
        let button = UILabel()
        button.text = "Connect"
        button.backgroundColor = .systemBlue
        button.textColor = .white
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 8
        button.addTapHandler { [weak self] in
            self?.view.endEditing(true)
            idField.isEnabled = false
            self?.connect(id: idField.text)
            self?.playButton.isHidden = false
        }
        button.textAlignment = .center
        button.pin(.height).const(48).equal()

        stackView.addArrangedSubview(button)

        playButton.text = "Pause"
        playButton.backgroundColor = .systemGreen
        playButton.textColor = .white
        playButton.layer.masksToBounds = true
        playButton.layer.cornerRadius = 8
        playButton.addTapHandler { [weak self] in
            if self?.playButton.text == "Pause" {
                WSManager.shared.sendStatus(.stop)
                self?.playButton.text = "Start"
            } else {
                WSManager.shared.sendStatus(.start)
                self?.playButton.text = "Pause"
            }
        }
        playButton.textAlignment = .center
        playButton.pin(.height).const(48).equal()
        stackView.addArrangedSubview(playButton)

        receiveTextView.pin(.height).const(480).equal()
        stackView.addArrangedSubview(receiveTextView)
    }

    func connect(id: String?) {
        WSManager.shared.connectToWebSocket(type: .phone, id: id)
        WSManager.shared.receiveData { [weak self] text in
            DispatchQueue.main.async {
                self?.receiveTextView.text = (self?.receiveTextView.text ?? "") + "\n" + text
            }
        }
    }
}
