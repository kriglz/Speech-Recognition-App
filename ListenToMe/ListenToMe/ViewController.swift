//
//  ViewController.swift
//  ListenToMe
//
//  Created by Kristina Gelzinyte on 8/10/17.
//  Copyright © 2017 Kristina Gelzinyte. All rights reserved.
//

import UIKit
import Speech

extension UILabel {
    
    func animate(newText: String, characterDelay: TimeInterval) {
        
        DispatchQueue.main.async {
            
            self.text = ""
            
            for (index, character) in newText.characters.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + characterDelay * Double(index)) {
                    self.text?.append(character)
                }
            }
        }
    }
}




class ViewController: UIViewController, SFSpeechRecognizerDelegate {

    
    @IBOutlet weak var intoLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var microphonebutton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        microphonebutton.isEnabled = false
        speechRecognizer?.delegate = self
        
        
        SFSpeechRecognizer.requestAuthorization{ authStatus in
            var isButtonEnabled = false
            
            switch authStatus {
                
            case .authorized:
                isButtonEnabled = true
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation {
                self.microphonebutton.isEnabled = isButtonEnabled
            }
        }
        intoLabel.animate(newText: "Hello, stranger. Please, talk to me. You can change background color by using RGB colors or go back to original one by reseting it.", characterDelay: 0.07)

    }
    
    @IBAction func activateSpeechRecognition(_ sender: Any) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphonebutton.isEnabled = false
            microphonebutton.setTitle("🗣", for: .normal)
            let color = UIColor(colorLiteralRed: 213/255, green: 228/255, blue: 235/255, alpha: 1)
            microphonebutton.backgroundColor = color

        } else {
            startRecording()
            microphonebutton.setTitle("⚫️", for: .normal)
            let color = UIColor(colorLiteralRed: 211/255, green: 0/255, blue: 71/255, alpha: 1)
            microphonebutton.backgroundColor = color

        }
        
    }
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))

    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    
    
    
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: {(result, error) in
            var isFinal = false
            if let result = result {
                let transcriptedString = result.bestTranscription.formattedString
                self.textView.text = transcriptedString
                
                let range = NSMakeRange(self.textView.text.characters.count - 1, 0)
                self.textView.scrollRangeToVisible(range)
                
                var lastString: String = ""
                for segment in result.bestTranscription.segments {
                    let segmentIndex = transcriptedString.index(transcriptedString.startIndex, offsetBy: segment.substringRange.location)
                    lastString = transcriptedString.substring(from: segmentIndex)
                }
                self.adjustTheColor(using: lastString)
                
                
                isFinal = (result.isFinal)
            }
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.microphonebutton.isEnabled = true
                
                self.microphonebutton.setTitle("🗣", for: .normal)
                let color = UIColor(colorLiteralRed: 213/255, green: 228/255, blue: 235/255, alpha: 1)
                self.microphonebutton.backgroundColor = color

            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        textView.font = UIFont(name: "American Typewriter", size: 16)
        textView.text = "I'm listening!"
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphonebutton.isEnabled = true
        } else {
            microphonebutton.isEnabled = false
        }
    }
    
    
    var currentColor = UIColor(colorLiteralRed: 213/255, green: 228/255, blue: 235/255, alpha: 1)
    var redCoefficient: Float = 213/255
    var greenCoefficient: Float = 228/255
    var blueCoefficient: Float = 235/255

    
    func adjustTheColor(using userColor: String) {
        print(userColor)
        switch userColor {
        case "red", "Red":
            redCoefficient -= 10/255
            textView.backgroundColor = UIColor(colorLiteralRed: redCoefficient, green: greenCoefficient, blue: blueCoefficient, alpha: 1)

            
        case "blue", "Blue":
            blueCoefficient -= 10/255
            textView.backgroundColor = UIColor(colorLiteralRed: redCoefficient, green: greenCoefficient, blue: blueCoefficient, alpha: 1)

            
        case "green", "Green":
            greenCoefficient -= 10/255
            textView.backgroundColor = UIColor(colorLiteralRed: redCoefficient, green: greenCoefficient, blue: blueCoefficient, alpha: 1)

            
        case "reset", "Reset":
            textView.backgroundColor = UIColor(colorLiteralRed: 240/255, green: 187/255, blue: 199/255, alpha: 1)

        default:
            break
        }

    }
    
}
























